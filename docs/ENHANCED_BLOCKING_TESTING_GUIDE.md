# Enhanced Return Buffer & Maintenance Testing Guide

## 🧪 **Quick Setup for Testing**

### **1. Database Setup**
```bash
# Apply the new migration
supabase db reset
# Or run specific migrations
supabase db push
```

### **2. Test Data Preparation**
Create test items in different categories:
- **Electronics**: Camera, Laptop, Phone
- **Tools**: Drill, Saw, Hammer
- **Clothing**: Dress, Suit, Shoes
- **Automotive**: Car, Motorcycle, Trailer

## 📋 **Manual Testing Scenarios**

### **🔄 Return Buffer Testing**

#### **Test 1: Category-Based Buffer Periods**
1. **Create bookings** for items in different categories
2. **Complete the bookings** (mark as returned)
3. **Check availability blocks** created:
   ```sql
   SELECT item_id, block_type, reason, 
          blocked_from, blocked_until, metadata
   FROM availability_blocks 
   WHERE block_type = 'post_rental'
   ORDER BY created_at DESC;
   ```
4. **Verify buffer periods**:
   - Electronics: 3+ days
   - Clothing: 1+ days
   - Tools: 2+ days
   - Automotive: 4+ days

#### **Test 2: Condition Adjustments**
1. **Create identical items** with different conditions:
   - Camera (Excellent) 
   - Camera (Fair) 
   - Camera (Poor)
2. **Complete bookings** for each
3. **Verify buffer differences**:
   - Excellent: 3 days
   - Fair: 4 days (3 + 1)
   - Poor: 5 days (3 + 2)

#### **Test 3: Delivery & High-Value Modifiers**
1. **Test delivery returns**:
   - Create booking with `delivery_required: true`
   - Complete booking
   - Verify +1 day added to buffer
2. **Test high-value items**:
   - Create expensive item (>$500/day)
   - Complete booking
   - Verify +1 day added to buffer

### **🔧 Maintenance Testing**

#### **Test 4: Manual Maintenance Blocks**
1. **Go to lender calendar**
2. **Long-press a date**
3. **Create maintenance block**:
   - Type: Cleaning (1 day)
   - Type: Repair (3 days)
   - Type: Deep Maintenance (2 days)
4. **Verify calendar display**:
   - Different colors for different types
   - Correct duration shown

#### **Test 5: Preventive Maintenance Scheduling**
1. **Create test item** with category
2. **Simulate rental history**:
   ```sql
   -- Insert fake completed rentals
   INSERT INTO rentals (item_id, status, end_date, created_at)
   VALUES 
   ('your-item-id', 'completed', NOW() - INTERVAL '5 days', NOW() - INTERVAL '10 days'),
   ('your-item-id', 'completed', NOW() - INTERVAL '10 days', NOW() - INTERVAL '15 days');
   ```
3. **Trigger maintenance check**:
   ```dart
   await AvailabilityService.schedulePreventiveMaintenance(
     itemId: 'your-item-id',
     categoryName: 'Electronics',
   );
   ```
4. **Verify maintenance scheduled** when thresholds reached

### **✅ Mark Ready Integration Testing**

#### **Test 6: Maintenance Block Prevention**
1. **Create maintenance block** for tomorrow
2. **Try to mark booking as ready** for same item
3. **Verify error message**:
   ```
   "Cannot mark Camera as ready: currently under repair 
   until 5/2/2025. Item will be available in 3 days."
   ```

#### **Test 7: Return Buffer Prevention**
1. **Complete a booking** (creates return buffer)
2. **Try to mark next booking ready** during buffer period
3. **Verify error message**:
   ```
   "Cannot mark Camera as ready: currently in return 
   processing period until 3/2/2025."
   ```

#### **Test 8: Timing Validation**
1. **Create booking** starting in 5 days
2. **Try marking ready** too early (6 days before)
3. **Verify timing error**:
   ```
   "Item can only be marked ready 2 days before pickup date. 
   You can mark this item ready in 4 days."
   ```

### **📅 Calendar Display Testing**

#### **Test 9: Enhanced Calendar Legend**
1. **Open lender calendar**
2. **Tap info/legend button**
3. **Verify new sections**:
   - Preparation Status
   - Return Processing
   - Scheduled Maintenance
   - Repair Work

#### **Test 10: Status Indicators**
1. **Create bookings** in different states:
   - Confirmed + Can Prep → Blue "CAN PREP"
   - Confirmed + Prepared → Orange "PREPARED"  
   - Confirmed + Available → Green "AVAILABLE"
   - Confirmed + Too Early → Grey "TOO EARLY"
2. **Verify calendar display** shows correct colors/text

#### **Test 11: Preparation Period Dots**
1. **Create booking** starting in 2 days
2. **Check calendar** for blue preparation dots
3. **Verify dots appear** 2-3 days before pickup date

## 🔍 **Database Verification Queries**

### **Check Return Buffer Calculations**
```sql
SELECT 
  i.name,
  c.name as category,
  i.condition,
  ab.reason,
  ab.metadata,
  EXTRACT(DAY FROM (ab.blocked_until - ab.blocked_from)) as buffer_days
FROM availability_blocks ab
JOIN items i ON ab.item_id = i.id
JOIN categories c ON i.category_id = c.id
WHERE ab.block_type = 'post_rental'
ORDER BY ab.created_at DESC;
```

### **Check Maintenance Scheduling**
```sql
SELECT 
  i.name,
  ab.metadata->>'maintenance_type' as type,
  ab.metadata->>'maintenance_trigger' as trigger,
  ab.reason,
  ab.blocked_from,
  ab.blocked_until
FROM availability_blocks ab
JOIN items i ON ab.item_id = i.id
WHERE ab.block_type = 'maintenance'
ORDER BY ab.created_at DESC;
```

### **Check Item Usage Stats**
```sql
SELECT 
  i.name,
  COUNT(r.id) as total_rentals,
  MAX(r.end_date) as last_rental,
  (
    SELECT MAX(ab.created_at) 
    FROM availability_blocks ab 
    WHERE ab.item_id = i.id AND ab.block_type = 'maintenance'
  ) as last_maintenance
FROM items i
LEFT JOIN rentals r ON i.id = r.item_id AND r.status = 'completed'
GROUP BY i.id, i.name
ORDER BY total_rentals DESC;
```

## 🎯 **Expected Results Summary**

### **✅ Return Buffer System**
- [ ] Different buffer periods by category
- [ ] Condition adjustments working
- [ ] Delivery/high-value modifiers applied
- [ ] Descriptive reasons generated
- [ ] Metadata properly stored

### **✅ Maintenance System**
- [ ] Manual maintenance blocks created
- [ ] Preventive maintenance scheduled
- [ ] Different maintenance types working
- [ ] Usage statistics tracked
- [ ] Batch processing functional

### **✅ Mark Ready Integration**
- [ ] Maintenance conflicts prevented
- [ ] Return buffer conflicts prevented
- [ ] Clear error messages shown
- [ ] Timing validation working

### **✅ Calendar Display**
- [ ] Enhanced legend visible
- [ ] Status indicators correct
- [ ] Preparation dots appearing
- [ ] Color coding accurate

## 🐛 **Common Issues & Debugging**

### **Issue: Buffer calculation wrong**
- Check category name normalization
- Verify condition values are correct
- Check constants in `AppConstants`

### **Issue: Maintenance not scheduling**
- Verify item has rental history
- Check threshold constants
- Look for existing maintenance blocks

### **Issue: Mark ready not blocked**
- Verify maintenance block exists
- Check block dates vs current date
- Confirm item ID matches

### **Issue: Calendar not updating**
- Refresh availability data
- Check BlocListener setup
- Verify state management

## 🚀 **Performance Testing**

### **Load Testing**
1. **Create 100+ items** with different categories
2. **Run batch maintenance check**:
   ```dart
   await AvailabilityService.checkAllItemsForMaintenance();
   ```
3. **Monitor performance** and database queries

### **Calendar Performance**
1. **Load calendar** with many bookings/blocks
2. **Check render time** for month view
3. **Test scrolling performance** between months

---

## 📊 **Test Completion Checklist**

- [ ] All return buffer scenarios tested
- [ ] All maintenance scenarios tested  
- [ ] Mark ready integration verified
- [ ] Calendar display confirmed
- [ ] Database queries validated
- [ ] Performance acceptable
- [ ] Error messages clear
- [ ] Edge cases handled

**🎉 When all tests pass, the enhanced blocking system is ready for production!**
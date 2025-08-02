import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Load environment variables
  await dotenv.load(fileName: '.env.development');

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  final supabase = Supabase.instance.client;

  try {


    // Update rental-1 to be active today
    await supabase.from('rentals').update({
      'start_date':
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'end_date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'status': 'in_progress',
      'total_price': 160.00,
    }).eq('id', 'rental-1');

    // Update rental-2 to be active today
    await supabase.from('rentals').update({
      'start_date': DateTime.now().toIso8601String(),
      'end_date': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
      'status': 'confirmed',
      'total_price': 360.00,
      'item_id': 'item-2',
      'renter_id': '550e8400-e29b-41d4-a716-446655440002',
    }).eq('id', 'rental-2');

    // Update rental-3 to be upcoming
    await supabase.from('rentals').update({
      'start_date':
          DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      'end_date': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
      'status': 'confirmed',
      'total_price': 240.00,
    }).eq('id', 'rental-3');

    // Update rental-4 to be upcoming
    await supabase.from('rentals').update({
      'start_date':
          DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'end_date': DateTime.now().add(const Duration(days: 9)).toIso8601String(),
      'status': 'pending',
      'total_price': 160.00,
    }).eq('id', 'rental-4');

    // Update rental-5 to be upcoming
    await supabase.from('rentals').update({
      'start_date':
          DateTime.now().add(const Duration(days: 10)).toIso8601String(),
      'end_date':
          DateTime.now().add(const Duration(days: 17)).toIso8601String(),
      'status': 'confirmed',
      'total_price': 840.00,
    }).eq('id', 'rental-5');


  } catch (e) {
    rethrow;
  }

  exit(0);
}

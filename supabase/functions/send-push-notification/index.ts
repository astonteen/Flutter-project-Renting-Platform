import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// Expo Push Notification types
interface ExpoMessage {
  to: string | string[]
  title?: string
  body?: string
  data?: Record<string, any>
  sound?: 'default' | null
  badge?: number
  channelId?: string
  categoryId?: string
  mutableContent?: boolean
  ttl?: number
  expiration?: number
  priority?: 'default' | 'normal' | 'high'
}

interface ExpoResponse {
  data: Array<{
    status: 'ok' | 'error'
    id?: string
    message?: string
    details?: any
  }>
}

interface SendNotificationRequest {
  user_id: string
  title: string
  body: string
  data?: Record<string, any>
  image_url?: string
  template_name?: string
  template_data?: Record<string, string>
}

interface SendBulkNotificationRequest {
  user_ids: string[]
  title: string
  body: string
  data?: Record<string, any>
  image_url?: string
  template_name?: string
  template_data?: Record<string, string>
}

serve(async (req) => {
  try {
    // Handle CORS preflight requests
    if (req.method === 'OPTIONS') {
      return new Response('ok', {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST',
          'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        },
      })
    }

    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }

    // Get environment variables
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const expoAccessToken = Deno.env.get('EXPO_ACCESS_TOKEN')

    if (!expoAccessToken) {
      throw new Error('Expo access token not configured')
    }

    // Initialize Supabase client with service role
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Parse request body
    const body = await req.json()
    console.log('Received request:', JSON.stringify(body, null, 2))

    // Determine if this is a single or bulk notification
    const isBulk = Array.isArray(body.user_ids)
    const userIds = isBulk ? body.user_ids : [body.user_id]

    if (!userIds || userIds.length === 0) {
      return new Response(
        JSON.stringify({ error: 'user_id or user_ids required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    let { title, body: messageBody, data = {}, image_url, template_name, template_data = {} } = body

    // If template_name is provided, fetch and process the template
    if (template_name) {
      const { data: template, error: templateError } = await supabase
        .from('notification_templates')
        .select('*')
        .eq('template_name', template_name)
        .eq('is_active', true)
        .single()

      if (templateError || !template) {
        console.error('Template not found:', template_name)
        return new Response(
          JSON.stringify({ error: `Template ${template_name} not found` }),
          { status: 404, headers: { 'Content-Type': 'application/json' } }
        )
      }

      // Process template variables
      title = processTemplate(template.title_template, template_data)
      messageBody = processTemplate(template.body_template, template_data)
      
      if (template.data_template) {
        const processedDataTemplate = JSON.stringify(template.data_template)
        const processedData = JSON.parse(processTemplate(processedDataTemplate, template_data))
        data = { ...data, ...processedData }
      }

      if (template.image_url && !image_url) {
        image_url = processTemplate(template.image_url, template_data)
      }
    }

    if (!title || !messageBody) {
      return new Response(
        JSON.stringify({ error: 'title and body are required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const results = []
    let successCount = 0
    let failureCount = 0

    // Process each user
    for (const userId of userIds) {
      try {
        // Get user devices and preferences
        const { data: devices, error: devicesError } = await supabase
          .rpc('get_user_devices', { target_user_id: userId })

        if (devicesError) {
          console.error('Error fetching devices for user', userId, devicesError)
          results.push({
            user_id: userId,
            success: false,
            error: 'Failed to fetch user devices'
          })
          failureCount++
          continue
        }

        if (!devices || devices.length === 0) {
          console.log('No active devices found for user:', userId)
          results.push({
            user_id: userId,
            success: false,
            error: 'No active devices found'
          })
          failureCount++
          continue
        }

        // Send notification to each device
        for (const device of devices) {
          try {
            // Validate Expo push token format
            if (!isValidExpoPushToken(device.device_token)) {
              console.log('Invalid Expo push token format for user:', userId)
              continue
            }

            // Check if user has notifications enabled
            const preferences = device.preferences
            if (preferences && preferences.push_enabled === false) {
              console.log('Push notifications disabled for user:', userId)
              continue
            }

            // Check notification type preferences
            if (data.type && preferences) {
              const notificationType = data.type
              if (
                (notificationType === 'delivery_update' && preferences.delivery_notifications === false) ||
                (notificationType === 'booking_update' && preferences.booking_notifications === false) ||
                (notificationType === 'message' && preferences.message_notifications === false) ||
                (notificationType === 'payment_update' && preferences.payment_notifications === false)
              ) {
                console.log(`${notificationType} notifications disabled for user:`, userId)
                continue
              }
            }

            // Log notification attempt
            const { data: logResult, error: logError } = await supabase
              .rpc('log_push_notification', {
                target_user_id: userId,
                target_device_token: device.device_token,
                notification_type_param: data.type || 'general',
                title_param: title,
                body_param: messageBody,
                data_param: data,
                image_url_param: image_url
              })

            if (logError) {
              console.error('Error logging notification:', logError)
            }

            const logId = logResult

            // Prepare Expo message
            const expoMessage: ExpoMessage = {
              to: device.device_token,
              title,
              body: messageBody,
              data: {
                ...data,
                log_id: logId || ''
              },
              sound: 'default',
              priority: 'high'
            }

            // Send Expo notification
            const expoResponse = await fetch('https://exp.host/--/api/v2/push/send', {
              method: 'POST',
              headers: {
                'Accept': 'application/json',
                'Accept-encoding': 'gzip, deflate',
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${expoAccessToken}`
              },
              body: JSON.stringify(expoMessage)
            })

            const expoResult = await expoResponse.json()

            if (expoResponse.ok && expoResult.data && expoResult.data[0]?.status === 'ok') {
              console.log('Notification sent successfully to:', device.device_token.substring(0, 20))
              
              // Update log status
              if (logId) {
                await supabase.rpc('update_notification_status', {
                  log_id_param: logId,
                  status_param: 'sent'
                })
              }
              
              successCount++
            } else {
              console.error('Expo error:', expoResult)
              
              // Update log status with error
              if (logId) {
                await supabase.rpc('update_notification_status', {
                  log_id_param: logId,
                  status_param: 'failed',
                  error_message_param: JSON.stringify(expoResult)
                })
              }
              
              // Handle invalid tokens
              if (expoResult.data && expoResult.data[0]?.details?.error === 'DeviceNotRegistered') {
                // Mark device as inactive
                await supabase
                  .from('user_devices')
                  .update({ is_active: false })
                  .eq('device_token', device.device_token)
              }
              
              failureCount++
            }

          } catch (deviceError) {
            console.error('Error sending to device:', deviceError)
            failureCount++
          }
        }

        results.push({
          user_id: userId,
          success: true,
          devices_count: devices.length
        })

      } catch (userError) {
        console.error('Error processing user:', userId, userError)
        results.push({
          user_id: userId,
          success: false,
          error: userError.message
        })
        failureCount++
      }
    }

    // Return results
    const response = {
      success: true,
      total_users: userIds.length,
      success_count: successCount,
      failure_count: failureCount,
      results: isBulk ? results : results[0]
    }

    console.log('Final response:', JSON.stringify(response, null, 2))

    return new Response(
      JSON.stringify(response),
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      }
    )

  } catch (error) {
    console.error('Edge function error:', error)
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      }
    )
  }
})

// Helper function to process template variables
function processTemplate(template: string, data: Record<string, string>): string {
  let result = template
  
  for (const [key, value] of Object.entries(data)) {
    const placeholder = `{{${key}}}`
    result = result.replace(new RegExp(placeholder, 'g'), value)
  }
  
  return result
}

// Helper function to validate Expo push token format
function isValidExpoPushToken(token: string): boolean {
  return /^ExponentPushToken\[.+\]$/.test(token) || /^ExpoPushToken\[.+\]$/.test(token)
} 
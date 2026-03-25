/// <reference path="./globals.d.ts" />
import { createClient } from 'jsr:@supabase/supabase-js@2'
import { RtcTokenBuilder, Role } from 'npm:agora-token@2.0.5'

Deno.serve(async (request: Request) => {
  try {
    if (request.method !== 'POST') {
      return jsonResponse({ error: 'Method not allowed' }, 405)
    }

    const authorization = request.headers.get('Authorization')
    if (!authorization) {
      return jsonResponse({ error: 'Missing authorization header' }, 401)
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    const agoraAppId = Deno.env.get('AGORA_APP_ID') ?? ''
    const agoraAppCertificate = Deno.env.get('AGORA_APP_CERTIFICATE') ?? ''

    if (!supabaseUrl || !supabaseAnonKey) {
      return jsonResponse({ error: 'Supabase environment is not configured' }, 500)
    }

    if (!agoraAppId || !agoraAppCertificate) {
      return jsonResponse({ error: 'Agora secrets are not configured' }, 500)
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: {
          Authorization: authorization,
        },
      },
    })

    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser()

    if (userError || !user) {
      return jsonResponse({ error: 'Unauthorized' }, 401)
    }

    const body = await request.json().catch(() => ({})) as {
      appointmentId?: string
      channelName?: string
      expiresInSeconds?: number
      role?: string
    }

    const appointmentId = (body.appointmentId ?? '').trim()
    const channelName = (body.channelName ?? '').trim()
    const expiresInSeconds = normalizeExpiry(body.expiresInSeconds)

    if (!appointmentId || !channelName) {
      return jsonResponse({ error: 'appointmentId and channelName are required' }, 400)
    }

    const expectedChannelName = buildAppointmentChannel(appointmentId)
    if (channelName !== expectedChannelName) {
      return jsonResponse({ error: 'Channel name does not match the appointment' }, 400)
    }

    const { data: appointment, error: appointmentError } = await supabase
      .from('appointments')
      .select('id, patient_id, doctor_id, status')
      .eq('id', appointmentId)
      .maybeSingle()

    if (appointmentError || !appointment) {
      return jsonResponse({ error: 'Appointment not found' }, 404)
    }

    const isParticipant =
      appointment['patient_id'] === user.id || appointment['doctor_id'] === user.id

    if (!isParticipant) {
      return jsonResponse({ error: 'Forbidden' }, 403)
    }

    if (appointment['status'] !== 'Accepted' && appointment['status'] !== 'Completed') {
      return jsonResponse({ error: 'Video call is available only for accepted appointments' }, 409)
    }

    const privilegeExpiredTs = Math.floor(Date.now() / 1000) + expiresInSeconds
    const token = RtcTokenBuilder.buildTokenWithAccount(
      agoraAppId,
      agoraAppCertificate,
      channelName,
      user.id,
      resolveRole(body.role),
      privilegeExpiredTs,
    )

    return jsonResponse({
      token,
      appId: agoraAppId,
      channelName,
      appointmentId,
      expiresInSeconds,
      expiresAt: privilegeExpiredTs,
      account: user.id,
    })
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : 'Unexpected server error' },
      500,
    )
  }
})

function resolveRole(role?: string) {
  if ((role ?? '').toLowerCase() === 'subscriber') {
    return Role.SUBSCRIBER
  }
  return Role.PUBLISHER
}

function normalizeExpiry(value?: number) {
  if (typeof value !== 'number' || Number.isNaN(value)) {
    return 3600
  }

  if (value < 60) {
    return 60
  }

  if (value > 7200) {
    return 7200
  }

  return Math.floor(value)
}

function buildAppointmentChannel(appointmentId: string) {
  const normalized = appointmentId.trim().replace(/[^a-zA-Z0-9_-]/g, '_')
  if (!normalized) {
    return 'test'
  }
  return `appointment_${normalized}`
}

function jsonResponse(payload: unknown, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      'Content-Type': 'application/json',
    },
  })
}

declare module 'jsr:@supabase/supabase-js@2' {
  export function createClient(
    url: string,
    key: string,
    options?: {
      global?: {
        headers?: Record<string, string>
      }
    },
  ): {
    auth: {
      getUser(): Promise<{
        data: { user: { id: string } | null }
        error: unknown
      }>
    }
    from(table: string): {
      select(columns: string): {
        eq(column: string, value: string): {
          maybeSingle(): Promise<{
            data:
              | {
                  id: string
                  patient_id: string
                  doctor_id: string
                  status: string
                }
              | null
            error: unknown
          }>
        }
      }
    }
  }
}

declare module 'npm:agora-token@2.0.5' {
  export const RtcTokenBuilder: {
    buildTokenWithAccount(
      appId: string,
      appCertificate: string,
      channelName: string,
      account: string,
      role: number,
      privilegeExpiredTs: number,
    ): string
    buildTokenWithUid(
      appId: string,
      appCertificate: string,
      channelName: string,
      uid: number,
      role: number,
      privilegeExpiredTs: number,
    ): string
  }

  export const Role: {
    SUBSCRIBER: number
    PUBLISHER: number
  }
}

declare const Deno: {
  serve(handler: (request: Request) => Response | Promise<Response>): void
  env: {
    get(key: string): string | undefined
  }
}

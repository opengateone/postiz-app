// Fallback when the private OpenGate modules (modules/og) are not checked out:
// the fork then builds and runs as plain Postiz. Keep the exports in sync with modules/og.
export const ogBackendModules: any[] = [];
export const ogAuthenticatedControllers: any[] = [];
export const ogPublicControllers: any[] = [];

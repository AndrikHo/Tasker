// Tasker — passkeys_web compatibility shim.
//
// supabase_flutter pulls in the `passkeys` plugin transitively. Its web
// implementation (`passkeys_web`) is an endorsed federated plugin, so Flutter
// auto-registers it at startup. During registration it calls
// `PasskeyAuthenticator.init()`. Corbado ships only TypeScript source for that
// global (no published CDN bundle), so without it `PasskeyAuthenticator` is
// undefined and the whole app crashes on boot with:
//   "Null check operator used on a null value"
//
// Tasker authenticates via OAuth providers (Apple / Google / KakaoTalk /
// Facebook), NOT passkeys, so we never invoke register/login. This shim
// provides the global the plugin expects: capability-detection methods return
// real, accurate results; register/login reject loudly so any accidental use
// surfaces immediately instead of failing silently.
(function () {
  "use strict";

  function hasPasskeySupport() {
    return Boolean(window.PublicKeyCredential);
  }

  async function isUserVerifyingPlatformAuthenticatorAvailable() {
    if (!window.PublicKeyCredential) return undefined;
    try {
      return await window.PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();
    } catch (_) {
      return undefined;
    }
  }

  async function isConditionalMediationAvailable() {
    if (!window.PublicKeyCredential || !window.PublicKeyCredential.isConditionalMediationAvailable) {
      return undefined;
    }
    try {
      return await window.PublicKeyCredential.isConditionalMediationAvailable();
    } catch (_) {
      return undefined;
    }
  }

  function notSupported() {
    return Promise.reject(
      new Error(
        "Passkey authentication is not enabled in Tasker. " +
          "Sign in with Apple, Google, KakaoTalk or Facebook instead."
      )
    );
  }

  window.PasskeyAuthenticator = {
    init: function () {},
    register: function () {
      return notSupported();
    },
    login: function () {
      return notSupported();
    },
    cancelCurrentAuthenticatorOperation: function () {},
    isUserVerifyingPlatformAuthenticatorAvailable: isUserVerifyingPlatformAuthenticatorAvailable,
    isConditionalMediationAvailable: isConditionalMediationAvailable,
    hasPasskeySupport: hasPasskeySupport,
  };
})();

// Temporary workarounds for generator edge-cases.
// These extensions provide missing typealiases for cases where the OpenAPI
// document uses `null` as a variant in a `oneOf`, which currently produces
// an associated value type that is not emitted by the generator.

import Foundation

// The `/api/token/test` response uses additionalProperties oneOf [object, null].
// Map the `null` payload to `Never` to satisfy the associated value type.
extension Operations.tokenTest.Output.Ok.Body.jsonPayload.additionalPropertiesPayload {
  typealias Case2Payload = Never
}


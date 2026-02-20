/**
 * @name Server-side request forgery (SSRF)
 * @description Passing user-controlled URLs to HTTP client functions like axios.get()
 *              allows attackers to make requests to internal services.
 * @kind problem
 * @problem.severity error
 * @id js/globomantics/ssrf-detection
 * @tags security
 *       external/cwe/cwe-918
 */

import javascript

from CallExpr call, DotExpr dot
where
  call.getCallee() = dot and
  dot.getBase().(VarAccess).getName() = "axios" and
  dot.getPropertyName().regexpMatch("get|post|put|delete|patch|request")
select call, "Potential SSRF: axios call may use user-controlled URL. Validate and allowlist target URLs (CWE-918)."

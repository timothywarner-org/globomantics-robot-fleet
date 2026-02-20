/**
 * @name Open redirect
 * @description Redirecting users to a URL taken directly from the query string
 *              allows phishing attacks via open redirects.
 * @kind problem
 * @problem.severity warning
 * @id js/globomantics/open-redirect
 * @tags security
 *       external/cwe/cwe-601
 */

import javascript

from MethodCallExpr call
where
  call.getMethodName() = "redirect" and
  call.getNumArgument() >= 1
select call, "Potential open redirect: validate the target URL against an allowlist before redirecting (CWE-601)."

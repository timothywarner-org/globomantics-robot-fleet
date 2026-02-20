/**
 * @name Eval injection
 * @description Using eval() with user-controlled input allows arbitrary code execution.
 * @kind problem
 * @problem.severity error
 * @id js/globomantics/eval-injection
 * @tags security
 *       external/cwe/cwe-094
 */

import javascript

from CallExpr call
where call.getCalleeName() = "eval"
select call, "Dangerous eval() call detected. Avoid eval() to prevent code injection (CWE-094)."

/**
 * @name Hardcoded secrets in source code
 * @description Storing secrets such as API keys and passwords directly in source code
 *              risks credential exposure if the repository is shared or compromised.
 * @kind problem
 * @problem.severity warning
 * @id js/globomantics/hardcoded-secrets
 * @tags security
 *       external/cwe/cwe-798
 */

import javascript

from VariableDeclarator decl, string name
where
  name = decl.getBindingPattern().(VarDecl).getName() and
  (
    name.regexpMatch("(?i).*(SECRET|PASSWORD|API_KEY|ACCESS_KEY).*")
  ) and
  decl.getInit() instanceof StringLiteral
select decl, "Hardcoded secret in variable '" + name + "'. Use environment variables instead (CWE-798)."

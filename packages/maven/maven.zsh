# Maven. ~/.m2/settings.xml references secrets as ${env.NAME}; running Maven
# through `with-secrets` fetches them from Proton Pass for that build only
# (GITHUB_TOKEN globally, plus e.g. a profile's ARTIFACTORY_TOKEN). They are
# never exported into your shell.
#
# NOTE: tools that run Maven themselves (IntelliJ) won't get these. Start them
# from a shell through with-secrets, or set the env vars in their run config.

mvn() { with-secrets -- mvn "$@"; }

# maven wrapper shortcuts
alias mw='with-secrets -- ./mvnw'
alias mws='./mvnw spotless:apply'                          # format code (no secrets needed)
alias mwv='with-secrets -- ./mvnw clean verify'            # full build + tests
alias mwi='with-secrets -- ./mvnw clean install -DskipTests'

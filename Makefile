zip:
	rm ca.cybera.PostgreSql.zip || true
	zip -r ca.cybera.PostgreSql.zip *

upload:
	murano package-import --exists-action u ca.cybera.PostgreSql.zip

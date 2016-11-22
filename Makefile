zip:
	rm ca.cybera.PostgreSQL.zip || true
	zip -r ca.cybera.PostgreSQL.zip *

upload:
	murano package-import --exists-action u ca.cybera.PostgreSQL.zip

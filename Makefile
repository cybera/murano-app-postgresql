all: zip upload

zip:
	rm ca.cybera.PostgreSQL.zip || true
	zip -r ca.cybera.PostgreSQL.zip *

upload:
	murano package-import --is-public --exists-action u ca.cybera.PostgreSQL.zip

server:=localhost
port:=8443
PEM_FILE=certfile.pem

SECRET_FILE_PLAIN=key/secret.txt
SECRET_FILE_ENCRYPTED=key/secret.enc
PRIVATE_KEY=private.key
PUBLIC_KEY=public.key
KEY_SIZE=1024

server-certificate:
	rm medium.jks || true && \
	keytool -genkey \
		-keyalg RSA \
		-alias medium \
		-keystore medium.jks \
		-storepass password \
		-validity 365 \
		-keysize 4096 \
		-storetype pkcs12 \
		-ext "SAN:c=DNS:localhost,IP:127.0.0.1" && \
	cp medium.jks server/src/main/resources/ && \
	rm medium.jks

start-server:
	cd server && mvn spring-boot:run

dump-certificate:
	echo \
    	| openssl s_client -connect $(server):$(port) 2>/dev/null \
    	| openssl x509 -text

extract:
	openssl s_client -connect $(server):$(port) 2>/dev/null </dev/null \
	| sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' \
	| openssl x509 -outform der \
	| keytool -import -alias $$(date +%s) -keystore cacerts --storepass changeit -noprompt && \
	cp cacerts client/src/main/resources

show-pem:
	openssl s_client -connect $(server):$(port) 2>/dev/null </dev/null \
	|  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'

show-der:
	openssl s_client -connect $(server):$(port) 2>/dev/null </dev/null \
	| sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' \
	| openssl x509 -outform der

write-pem:
	openssl s_client -connect $(server):$(port) 2>/dev/null </dev/null \
	|  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' \
	> $(PEM_FILE)

decrypt-pem:
	openssl x509 -in $(PEM_FILE) -text -noout

verify-signer-authority:
	openssl x509 -in $(PEM_FILE) -text -noout -issuer -issuer_hash

verify-hash-value:
	openssl x509 -in $(PEM_FILE) -hash -noout

verify-dates-from-pem:
	openssl x509 -in $(PEM_FILE) -dates -noout

verify-dates-from-url:
	openssl s_client -connect $(server):$(port) 2>/dev/null </dev/null | openssl x509 -noout -enddate

verify-ssl-v2:
	openssl s_client -connect $(server):$(port) -ssl2

verify-tls-1.0:
	openssl s_client -connect $(server):$(port) -tls1

verify-tls-1.1:
	openssl s_client -connect $(server):$(port) -tls1_1

verify-tls-1.2:
	openssl s_client -connect $(server):$(port) -tls1_2

verify-tls-1.3:
	openssl s_client -connect $(server):$(port) -tls1_3

verify-cipher-ECDHE-ECDSA-AES256-SHA:
	openssl s_client -cipher 'ECDHE-ECDSA-AES256-SHA' -connect $(server):$(port)

verify-cipher-AES256-SHA:
	openssl s_client -cipher 'AES256-SHA' -connect $(server):$(port)

run-client:
	cd client && mvn compile exec:java \
		-Dexec.mainClass="main.client.BookMainClient" \
		-Djavax.net.ssl.trustStore="./src/main/resources/cacerts" \
		-Djavax.net.ssl.trustStorePassword="changeit" \
		-Djavax.net.ssl.trustStoreType="PKCS12"

dump-trustore:
	keytool -list -keystore client/src/main/resources/cacerts

# Symetric encryption

symetric-encrypt-with-password:
	openssl aes-256-cbc -salt -a -e -in $(SECRET_FILE_PLAIN) -out $(SECRET_FILE_ENCRYPTED)

symetric-decrypt-with-password:
	openssl aes-256-cbc -salt -a -d -in $(SECRET_FILE_ENCRYPTED) -out $(SECRET_FILE_PLAIN) 

# Asymetric encryption

asymetric-generate-key-pair:
	mkdir -p key && \
	openssl genrsa -aes256 -out key/alice-$(PRIVATE_KEY) $(KEY_SIZE) && \
	openssl genrsa -aes256 -out key/bob-$(PRIVATE_KEY) $(KEY_SIZE)

asymetric-export-public-key:
	openssl rsa -in key/alice-$(PRIVATE_KEY) -pubout -out key/alice-$(PUBLIC_KEY) && \
	openssl rsa -in key/bob-$(PRIVATE_KEY) -pubout -out key/bob-$(PUBLIC_KEY)

asymetric-show-private-key:
	openssl rsa -in key/alice-$(PRIVATE_KEY) -text -noout && \
	openssl rsa -in key/bob-$(PRIVATE_KEY) -text -noout

asymetric-xchange: 
	@read -p "Alice's secret : " SECRET_INPUT && \
	echo $${SECRET_INPUT} > $(SECRET_FILE_PLAIN) && \
	openssl rsautl -encrypt -in $(SECRET_FILE_PLAIN) -pubin -inkey key/bob-$(PUBLIC_KEY) -out $(SECRET_FILE_ENCRYPTED) && \
	echo ">>>>>>>>> Alice sends the secret, encrypted with Bob's public key" && \
	rm $(SECRET_FILE_PLAIN) && \
	echo "---------" && \
	cat $(SECRET_FILE_ENCRYPTED) && \
	echo "\n---------" && \
	echo "\n>>>>>>>>> Bob receives Alice encrypted message, and decrypts it with his password-protected private key" && \
	openssl rsautl -decrypt -in $(SECRET_FILE_ENCRYPTED) -inkey key/bob-$(PRIVATE_KEY) -out $(SECRET_FILE_PLAIN) && \
	echo "---------" && \
	cat $(SECRET_FILE_PLAIN) && \
	echo "---------"

server:=localhost
port:=8443

server-certificate:
	rm medium.jks || true && \
	keytool -genkey -keyalg RSA -alias medium -keystore medium.jks -storepass password -validity 365 -keysize 4096 -storetype pkcs12 -ext "SAN:c=DNS:localhost,IP:127.0.0.1" && \
	cp medium.jks server/src/main/resources/ && \
	rm medium.jks

start-server:
	cd server && mvn spring-boot:run

dump-certificate:
	echo | \
    	openssl s_client -connect $(server):$(port) 2>/dev/null | \
    	openssl x509 -text

extract-certificate:
	openssl s_client -connect $(server):$(port) 2>/dev/null </dev/null |  sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > certificate.pem && \
	openssl x509 -outform der -in certificate.pem -out certificate.der && \
	keytool -import -alias your-alias -keystore cacerts -file certificate.der && \
	cp cacerts client/src/main/resources && \
	rm *.der *.pem cacert*

run-client:
	cd client && mvn compile exec:java \
		-Dexec.mainClass="main.client.BookMainClient" \
		-Djavax.net.ssl.trustStore="./src/main/resources/cacerts" \
		-Djavax.net.ssl.trustStorePassword="changeit" \
		-Djavax.net.ssl.trustStoreType="PKCS12" \


dump-trustore:
	keytool -list -keystore client/src/main/resources/cacerts
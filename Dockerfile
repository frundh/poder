FROM ubuntu

RUN set -ex; \ 
    apt-get update && apt-get install -y --no-install-recommends ca-certificates curl jq; \
    curl -SL https://storage.googleapis.com/kubernetes-release/release/v1.15.4/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl; chmod +x /usr/local/bin/kubectl; \
    apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*; 
    
COPY poder.sh /usr/local/bin/poder
RUN chmod +x /usr/local/bin/poder

ENTRYPOINT [ "poder" ]
CMD [ "--help" ]
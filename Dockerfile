FROM golang:1.15.8 as builder

COPY ./ /app
WORKDIR /app
RUN cd /router-plugin && go build -buildmode=plugin -o router-plugin.so .

RUN cd /proxy-plugin && go build -buildmode=plugin -o proxy-plugin.so .

FROM devopsfaith/krakend:1.3.0



COPY . /etc/krakend/
COPY --from=builder /router-plugin/router-plugin.so /etc/krakend/plugins/
COPY --from=builder /proxy-plugin/proxy-plugin.so /etc/krakend/plugins/

RUN FC_ENABLE=1 \
FC_SETTINGS="config/settings/$ENV" \
FC_PARTIALS="config/partials" \
FC_TEMPLATES="config/templates" \
krakend check -t -d -c "config/krakend.json"

ENTRYPOINT FC_ENABLE=1 \
FC_SETTINGS="/etc/krakend/config/settings/$ENV" \
FC_PARTIALS="/etc/krakend/config/partials" \
FC_TEMPLATES="/etc/krakend/config/templates" \
krakend run -d -c "/etc/krakend/config/krakend.json" -p $PORT

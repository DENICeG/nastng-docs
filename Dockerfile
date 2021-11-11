# build OpenAPI content
FROM node:13.12.0-alpine as api
WORKDIR /app
ENV PATH /app/node_modules/.bin:$PATH
COPY api.yaml ./
RUN npm install -g redoc-cli
RUN redoc-cli bundle -o api.html api.yaml


# build for production mode
FROM asciidoctor/docker-asciidoctor as build
WORKDIR /out
COPY docs ./docs
WORKDIR /out/docs
RUN asciidoctor '**/*.adoc'
RUN rm **/*.adoc *.adoc

FROM nginx:stable-alpine
RUN apk add shadow
RUN useradd -u 30000 nast-docs
COPY --from=build --chown=30000:30000 /out/docs /usr/share/nginx/html/docs
COPY --from=api --chown=30000:30000 /app/api.html /usr/share/nginx/html/docs/nast/api.html

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

RUN chown -R nast-docs:nast-docs /usr/share/nginx/html && chmod -R 755 /usr/share/nginx/html && \
        chown -R nast-docs:nast-docs /var/cache/nginx && \
        chown -R nast-docs:nast-docs /var/log/nginx && \
        chown -R nast-docs:nast-docs /etc/nginx/conf.d
RUN touch /var/run/nast-docs.pid && \
        chown -R nast-docs:nast-docs /var/run/nast-docs.pid

WORKDIR /env
EXPOSE 8080
RUN apk add --no-cache bash
USER nast-docs
CMD ["/bin/bash", "-c", "nginx -g \"daemon off;\""]
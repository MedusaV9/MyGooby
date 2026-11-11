FROM node:22-alpine
WORKDIR /app
COPY package.json ./
COPY src ./src
ENV NODE_ENV=production
ENV GOOBY_PORT=8080
ENV GOOBY_DATA=/data/store.json
RUN mkdir -p /data && chown node:node /data
VOLUME /data
EXPOSE 8080
USER node
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s CMD node -e "const p=process.env.PORT||process.env.GOOBY_PORT||8080;fetch('http://127.0.0.1:'+p+'/v1/info').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "src/server.js"]

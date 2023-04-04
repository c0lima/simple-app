FROM nginx:alpine
RUN pwd
RUN ls
COPY build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
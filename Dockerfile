FROM tomcat
RUN echo "Hello World"
COPY **/target/**/*.jar /tmp

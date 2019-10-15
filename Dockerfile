FROM tomcat
RUN echo "Hello World"
COPY *.jar /tmp

FROM tomcat
RUN echo "Hello World"
RUN mkdir -p /tmp/abc
COPY *.jar /tmp/abc/
COPY /tmp/abc/*.jar /usr/local/tomcat/webapps
RUN ls -ltr /usr/local/tomcat/webapps

FROM tomcat
RUN echo "Hello World"
RUN mkdir -p /tmp/abc
COPY *.jar /usr/local/tomcat/webapps/
RUN ls -ltr /usr/local/tomcat/webapps/

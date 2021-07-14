(echo "testing inside container" && \
cat /startup.sh && \
cat /etc/supervisor/supervisord.conf && \
cat /etc/supervisor/conf.d/supervisord.conf && \
geckodriver --version && \
python3 --version && \
pip --version && \
firefox -width=1080 -height=720 -url http://google.com && \
exit)
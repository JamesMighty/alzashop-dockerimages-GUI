(echo '== testing inside container' && \
echo '== print current interfaces:\n' && \
ip a && \
echo '== print file "/startup.sh":\n' && \
cat /startup.sh && \
echo '== print file "/etc/supervisor/supervisord.conf":\n' && \
cat /etc/supervisor/supervisord.conf && \
echo '== print file "/etc/supervisor/conf.d/supervisord.conf":\n' && \
cat /etc/supervisor/conf.d/supervisord.conf && \
echo '== geckodriver version:\n' && \
geckodriver --version && \
echo '== python version:\n' && \
python3 --version && \
echo '== pip version:\n' && \
pip --version && \
echo '== firefox version:\n' && \
firefox --version && \
sleep 5 && \
echo '== trying to open google in firefox:\n' && \
firefox -width=1080 -height=720 -url http://google.com && \
sleep 5 && \
echo '== exit:\n' && \
exit)
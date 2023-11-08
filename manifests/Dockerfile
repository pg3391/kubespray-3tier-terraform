# Use a base image with a minimal Linux distribution
FROM ubuntu:20.04

# Install necessary packages
RUN apt-get update && apt-get install -y \
    xfce4 \
    tightvncserver \
    xfonts-base \
    firefox

# Set a VNC password (change 'password' to your desired password)
RUN echo 'password' | vncpasswd -f > ~/.vnc/passwd
RUN chmod 600 ~/.vnc/passwd

# Expose VNC port
EXPOSE 5901

# Start VNC server with XFCE desktop and Firefox
CMD ["vncserver", ":1", "-localhost", "-geometry", "1280x720", "-depth", "24", "-dpi", "96", "-SecurityTypes", "None", "-fg"]


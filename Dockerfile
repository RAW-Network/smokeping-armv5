FROM arm32v5/debian:bookworm-slim

LABEL maintainer="RAW-Network" \
      description="Smokeping container for ARMv5 legacy device"

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    LANG=en_US.UTF-8

# Install Dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        smokeping \
        apache2 \
        libapache2-mod-fcgid \
        fcgiwrap \
        fping \
        ssmtp \
        curl \
        tcptraceroute \
        dnsutils \
        ca-certificates \
        tzdata \
        locales \
        fonts-dejavu-core \
        procps && \
    # Setup Locale
    sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=en_US.UTF-8 && \
    # Set permissions for probes
    chmod a+s /usr/bin/tcptraceroute && \
    # Prepare runtime directories
    mkdir -p /config /data /defaults /var/run/smokeping /var/log/smokeping

# Backup original Debian config files to defaults
RUN cp /etc/smokeping/basepage.html /defaults/ && \
    cp /etc/smokeping/smokemail /defaults/ && \
    cp /etc/smokeping/tmail /defaults/

# Copy local binaries and configs
COPY defaults/tcpping /usr/bin/tcpping
RUN chmod +x /usr/bin/tcpping

COPY defaults/smokeping.conf /etc/apache2/conf-available/smokeping.conf
COPY defaults/smoke-conf/ssmtp.conf /etc/ssmtp/ssmtp.conf

# Copy custom user configs to staging area
COPY defaults/smoke-conf/* /defaults/
COPY defaults/smokeping_secrets /defaults/smokeping_secrets
RUN chmod 600 /defaults/smokeping_secrets

# Generate master config file with includes
RUN echo "@include /config/General" > /defaults/config && \
    echo "@include /config/Alerts" >> /defaults/config && \
    echo "@include /config/Database" >> /defaults/config && \
    echo "@include /config/Presentation" >> /defaults/config && \
    echo "@include /config/Probes" >> /defaults/config && \
    echo "@include /config/Slaves" >> /defaults/config && \
    echo "@include /config/Targets" >> /defaults/config

# Finalize Setup
RUN \
    # Fix cropper.js path for zoom function
    sed -i 's#src="/cropper/#src="cropper/#' /defaults/basepage.html || true && \
    \
    # Disable heavy modules, enable required ones
    a2dismod -f status autoindex && \
    a2enmod cgi fcgid alias env headers && \
    \
    # Optimize Apache MPM for low RAM devices
    echo "<IfModule mpm_prefork_module>\n \
        StartServers 1\n \
        MinSpareServers 1\n \
        MaxSpareServers 2\n \
        MaxRequestWorkers 5\n \
        MaxConnectionsPerChild 1000\n \
    </IfModule>" > /etc/apache2/conf-available/optimized-resource.conf && \
    a2enconf optimized-resource && \
    a2enconf smokeping && \
    \
    # Cleanup to reduce image size
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
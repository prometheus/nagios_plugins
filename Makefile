VERSION  := 0.3.0
TARGET   := prometheus-nagios_plugins
ARCHIVE  := $(TARGET)-$(VERSION).tar.gz

$(ARCHIVE): *.sh
	tar -czf $@ *.sh

upload: REMOTE     ?= $(error "can't upload, REMOTE not set")
upload: REMOTE_DIR ?= $(error "can't upload, REMOTE_DIR not set")
upload: $(ARCHIVE)
	scp $(ARCHIVE) $(REMOTE):$(REMOTE_DIR)/$(ARCHIVE)

.PHONY: upload

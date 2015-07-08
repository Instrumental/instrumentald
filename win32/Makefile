prefix=.
MCS=mcs
MCSFLAGS=-reference:System.ServiceProcess.dll -reference:System.Configuration.dll -reference:System.Configuration.Install.dll
TARGET=build
SRC=src

all: InstrumentServer.exe

InstrumentServer.exe: $(SRC)/instrumental/*.cs
	mkdir -p $(TARGET)
	$(MCS) -out:$(TARGET)/$@ $(MCSFLAGS) $^

clean:
	rm $(TARGET)/*

install: all
	install -m 0755 $(TARGET)/InstrumentServer.exe $(prefix)/.


REM RTC.BAS
REM
REM MachiKania type M : RTC-4543SA
REM ------------------+------------------------
REM           14(B14) : CE
REM           15(B15) : WR
REM                   : 3.3V
REM           16(E5 ) : CLK
REM           17(E6 ) : DATA
REM                   : GND

USECLASS RTC
R=NEW(RTC)

R.INIT(20,2,23,13,4,0)
R.WR()

WAIT 60

WHILE 1
  R.RD()
REM   CLS
REM  CURSOR 0,0
  PRINT "20"+DEC$(R.YEAR)+" "+DEC$(R.MONTH)+"/"+DEC$(R.DAY)+" ";
  PRINT "("+R.DOWTXT$()+")"+" ";
  PRINT DEC$(R.HOUR)+":"+DEC$(R.MIN)+":"+DEC$(R.SEC)
  WAIT 60
WEND
END

REM === CLASS "RTC" ===
OPTION CLASSCODE

FIELD PUBLIC YEAR,MONTH,DAY,HOUR,MIN,SEC,DOW

METHOD WAITu
  USETIMER ARGS(1)
  WHILE TIMER() > 0
  WEND
RETURN

METHOD DOWNUM  REM Day of week number (SUN=1...SUT=7)
  VAR Y,M
  IF ((MONTH = 1) OR (MONTH = 2)) THEN
    Y=(YEAR+2000)-1
    M=MONTH+12
  ENDIF
RETURN (Y+Y/4-Y/100+Y/400+(13*M+8)/5+DAY)%7+1

METHOD DOWTXT  REM Day of week text
  VAR S
  S$="SUNMONTUEWEDTHUFRISAT"
  IF ARGS(0)=0 THEN
    RETURN S$((RTC::DOWNUM()-1)*3,3)
  ELSE
    RETURN S$((ARGS(1)-1)*3,3)
  ENDIF

METHOD CLOSE
  OUT 14,0    REM B14 CE
  OUT 15,0    REM B15 WR
  OUT 16,0    REM E5  CLK
  OUT 17,0    REM E6  DATA
RETURN

METHOD MODEWR
  OUT 15,1    REM B15 WR
  OUT 14,1    REM B14 CE
RETURN

METHOD MODERD
  OUT 15,0    REM B15 WR
  OUT 14,1    REM B14 CE
RETURN

METHOD CLK
  OUT 16,1    REM E5  CLK
  CALL RTC::WAITu(500)
  OUT 16,0    REM E5  CLK
  CALL RTC::WAITu(500)
RETURN

METHOD WRBIT
  IF (ARGS(1) AND 1) = 1 THEN
    OUT 17,1   REM E6  DATA
  ELSE
    OUT 17,0   REM E6  DATA
  ENDIF
  CALL RTC::CLK()
RETURN

METHOD RDBIT
  CALL RTC::CLK()
RETURN IN(17) AND 1 

METHOD WRDATA
  VAR A,B,I
  A=ARGS(1)
  B=ARGS(2)
  FOR I=0 TO B-1
    CALL RTC::WRBIT(A AND 1)
    A=A >> 1
  NEXT
  WAIT 1
RETURN

METHOD RDDATA
  VAR A,B,T,I
  A=ARGS(1)
  B=0
  T=0
  FOR I=0 TO A-1
    T=RTC::RDBIT()
    T=T << I
    B=B+T
  NEXT
RETURN B

METHOD INIT
  VAR A

  IF ARGS(0)=0 THEN
    YEAR=20
    MONTH=1
    DAY=1
    HOUR=0
    MIN=0
    SEC=0
    DOW=3
  ELSEIF ARGS(0)=6 THEN
    YEAR=ARGS(1)
    MONTH=ARGS(2)
    DAY=ARGS(3)
    HOUR=ARGS(4)
    MIN=ARGS(5)
    SEC=ARGS(6)
    DOW=RTC::DOWNUM()
  ELSE
    YEAR=ARGS(1)
    MONTH=ARGS(2)
    DAY=ARGS(3)
    HOUR=ARGS(4)
    MIN=ARGS(5)
    SEC=ARGS(6)
    DOW=ARGS(7)
  ENDIF

  DO
    CALL RTC::MODERD()
    CALL RTC::RDDATA(7)
    A=RTC::RDDATA(1)      REM FDT bit
    CALL RTC::RDDATA(44)  REM Idle reading
    CALL RTC::CLOSE()
  LOOP WHILE A=1
RETURN

METHOD WR
  CALL RTC::MODEWR()

  CALL RTC::WRDATA(SEC % 10,4)
  CALL RTC::WRDATA(SEC / 10,3)
  CALL RTC::WRDATA(0,1)   REM FDT bit(always set 0)

  CALL RTC::WRDATA(MIN % 10,4)
  CALL RTC::WRDATA(MIN / 10,3)
  CALL RTC::WRDATA(0,1)   REM user bit(0)

  CALL RTC::WRDATA(HOUR % 10,4)
  CALL RTC::WRDATA(HOUR / 10,2)
  CALL RTC::WRDATA(0,2)   REM user bit(0)

  CALL RTC::WRDATA(DOW,3) REM Day of week
  CALL RTC::WRDATA(0,1)   REM user bit(0)

  CALL RTC::WRDATA(DAY % 10,4)
  CALL RTC::WRDATA(DAY / 10,2)
  CALL RTC::WRDATA(0,2)   REM user bit(0)

  CALL RTC::WRDATA(MONTH % 10,4)
  CALL RTC::WRDATA(MONTH / 10,1)
  CALL RTC::WRDATA(0,2)   REM user bit(0)
  CALL RTC::WRDATA(0,1)   REM TM bit(always set 0)

  CALL RTC::WRDATA(YEAR % 10,4)
  CALL RTC::WRDATA(YEAR / 10,4)

  CALL RTC::CLOSE()
RETURN

METHOD RD
  VAR A,B

  CALL RTC::MODERD()

  A=RTC::RDDATA(4)
  B=RTC::RDDATA(3)
  SEC=A + (B * 10)
  A=RTC::RDDATA(1)   REM FDT bit

  A=RTC::RDDATA(4)
  B=RTC::RDDATA(3)
  MIN=A + (B * 10)
  A=RTC::RDDATA(1)   REM user bit

  A=RTC::RDDATA(4)
  B=RTC::RDDATA(2)
  HOUR=A + (B * 10)
  A=RTC::RDDATA(2)   REM user bit

  DOW=RTC::RDDATA(3) REM Day of week
  A=RTC::RDDATA(1)   REM user bit

  A=RTC::RDDATA(4)
  B=RTC::RDDATA(2)
  DAY=A + (B * 10)
  A=RTC::RDDATA(2)   REM user bit

  A=RTC::RDDATA(4)
  B=RTC::RDDATA(1)
  MONTH=A + (B * 10)
  A=RTC::RDDATA(2)   REM user bit
  A=RTC::RDDATA(1)   REM TM bit

  A=RTC::RDDATA(4)
  B=RTC::RDDATA(4)
  YEAR=A + (B * 10)

  CALL RTC::CLOSE()
RETURN

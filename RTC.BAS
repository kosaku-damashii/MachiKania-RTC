REM RTC.BAS
REM
REM This sample code use the following I/O ports settings.
REM   MachiKania type M : RTC-4543SA
REM   ------------------+------------------------
REM             14(B14) : CE
REM             15(B15) : WR
REM                     : 3.3V
REM             16(E5 ) : DATA
REM             18(E7 ) : CLK
REM                     : GND
REM If you need to use another I / O ports, please set them 
REM when you create a new object with the "NEW" function

REM === Sample Code ===
USECLASS RTC

REM CE=14, WR=15, DATA=16, CLK=18)
R=NEW(RTC,14,15,16,18)

REM 2020 Nov./21 17:47:30
R.SETTM(20,11,21,17,47,30)

WAIT 60

WHILE 1
  R.RD()
  PRINT "20"+DEC$(R.YEAR)+" "+DEC$(R.MONTH)+"/"+DEC$(R.DAY)+" ";
  PRINT "("+R.DOWTXT$()+")"+" ";
  PRINT DEC$(R.HOUR)+":"+DEC$(R.MIN)+":"+DEC$(R.SEC)
  WAIT 60
WEND
END

REM === CLASS "RTC" ===
OPTION CLASSCODE

FIELD PUBLIC YEAR,MONTH,DAY,HOUR,MIN,SEC,DOW
FIELD PRIVATE pCE,pWR,pCLK,pDATA

METHOD WAITu
  VAR I
  FOR I=ARGS(1)/15 TO 1 STEP -1: NEXT

  REM Please replace with follwing code if you want to interrupt timer version. 
  REM USETIMER ARGS(1)
  REM WHILE TIMER() = 0
  REM WEND
RETURN

METHOD DOWNUM  REM Day of week number (SUN=1...SUT=7)
  VAR Y,M
  IF ((MONTH = 1) OR (MONTH = 2)) THEN
    Y=(YEAR+2000)-1
    M=MONTH+12    
  ELSE
    Y=YEAR+2000
    M=MONTH    
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
  OUT pCE,0
  OUT pWR,0
  OUT pDATA,0
  OUT pCLK,0
RETURN

METHOD MODEWR
  OUT pWR,1
  OUT pCE,1
RETURN

METHOD MODERD
  OUT pWR,0
  OUT pCE,1
RETURN

METHOD CLK
  OUT pCLK,1
  CALL RTC::WAITu(750)
  OUT pCLK,0
  CALL RTC::WAITu(750)
RETURN

METHOD WRBIT
  IF (ARGS(1) AND 1) = 1 THEN
    OUT pDATA,1
  ELSE
    OUT pDATA,0
  ENDIF
  CALL RTC::CLK()
RETURN

METHOD RDBIT
  CALL RTC::CLK()
RETURN IN(pDATA) AND 1

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

REM Set I/O port
METHOD SETIO
  pCE=ARGS(1)
  pWR=ARGS(2)
  pDATA=ARGS(3)
  pCLK=ARGS(4)
RETURN

REM Set Time
METHOD SETTM
  VAR R

  IF ARGS(0)=6 THEN
    YEAR=ARGS(1)
    MONTH=ARGS(2)
    DAY=ARGS(3)
    HOUR=ARGS(4)
    MIN=ARGS(5)
    SEC=ARGS(6)
    DOW=RTC::DOWNUM()
    CALL RTC::WR()
  ELSE
    CALL RTC::RD()
  ENDIF
  IF YEAR<20 THEN R=-1 ELSE R=1   REM R=-1:Super capacitor maybe discharged.
RETURN R

METHOD INIT
  VAR A,R

  CALL RTC::SETIO(ARGS(1),ARGS(2),ARGS(3),ARGS(4))

  DO
    CALL RTC::MODERD()
    CALL RTC::RDDATA(7)
    A=RTC::RDDATA(1)      REM FDT bit
    CALL RTC::RDDATA(44)  REM Idle reading
    CALL RTC::CLOSE()
  LOOP WHILE A=1

  CALL RTC::RD()
  IF YEAR<20 THEN R=-1 ELSE R=1   REM R=-1:Super capacitor maybe discharged.

  IF R < 0 THEN
    PRINT "Please charge Super capacitor and set date and time with \"SETTM\" method.":END
  ENDIF
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

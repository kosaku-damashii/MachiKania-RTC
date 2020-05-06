REM RTC.BAS
REM
REM Default I/O ports setting is following.
REM   MachiKania type M : RTC-4543SA
REM   ------------------+------------------------
REM             14(B14) : CE
REM             15(B15) : WR
REM                     : 3.3V
REM             16(E5 ) : CLK
REM             17(E6 ) : DATA
REM                     : GND
REM If you need to use I/O port except above default I/O ports,
REM please set I/O ports with "SETIO" method before execute "INIT" method, 
REM   SETIO(CE, WR, CLK, DATA)


USECLASS RTC
R=NEW(RTC)

REM R.SETIO(14,15,16,18)  REM SETIO(CE, WR, CLK, DATA)

IF R.INIT(20,5,6,15,9,0) < 0 THEN
REM IF R.INIT() < 0 THEN
  PRINT "Please charge Super capacitor and set date and time with \"INIT\" method.":END
ENDIF

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
  OUT pCLK,0
  OUT pDATA,0
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

REM Set I/O port before execute INIT(), if you need to use I/O port except default ports.
METHOD SETIO
  pCE=ARGS(1)
  pWR=ARGS(2)
  pCLK=ARGS(3)
  pDATA=ARGS(4)
RETURN

METHOD INIT
  VAR A,R

  REM Set default ports, if user did not change default port's definition.
  IF pCE=pWR THEN
    pCE=14
    pWR=15
    pCLK=16
    pDATA=17
  ENDIF

  DO
    CALL RTC::MODERD()
    CALL RTC::RDDATA(7)
    A=RTC::RDDATA(1)      REM FDT bit
    CALL RTC::RDDATA(44)  REM Idle reading
    CALL RTC::CLOSE()
  LOOP WHILE A=1

  IF ARGS(0)=6 THEN
    YEAR=ARGS(1)
    MONTH=ARGS(2)
    DAY=ARGS(3)
    HOUR=ARGS(4)
    MIN=ARGS(5)
    SEC=ARGS(6)
    DOW=RTC::DOWNUM()
    CALL RTC::WR()
  ELSEIF ARGS(0)=7 THEN
    YEAR=ARGS(1)
    MONTH=ARGS(2)
    DAY=ARGS(3)
    HOUR=ARGS(4)
    MIN=ARGS(5)
    SEC=ARGS(6)
    DOW=ARGS(7)
    CALL RTC::WR()
  ELSE
    CALL RTC::RD()
  ENDIF
  IF YEAR<20 THEN R=-1 ELSE R=1   REM R=-1:Super capacitor maybe discharged.
RETURN R

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

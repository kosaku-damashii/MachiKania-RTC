# MachiKania-RTC
RTC Class for MachiKania type M

電気二重層コンデンサ(1.5F)を使って144時間(=６日間)RTCを動作させることが出来ます。

ハードウェアの作成は、実態配線図(ActualWiringDiagram.jpg)を参照してください。
これは、もともと、MachiKania type M用の外付けコントローラ基板だったものに、RTCの回路を追加したものです。
従って、RTCを動作させるだけであれば、外付けコントローラに必要な配線は不要です。
上記の実態配線図だと表面と裏面の配線が見辛いので、詳しくは、PasS( <http://uaubn.g2.xrea.com/pass/> )で作成した実態配線図( MachiKaniaTypeM用外付けコントローラ.pas )を参照して下さい。

注意点
　- WAITuメソッドを、TIMER割り込みを使用する方法ではなく、FORループで待つようにしたため、REMで該当箇所はコメントアウト
　　しました。もし、TIMER割り込みを使う方法を使用する場合は、REMで無効にしてあるコードに差し替えてください。
　- SETIOメソッドで、I/Oの設定を変更できるようにしました。
　　INITメソッドよりも前に実行してください。
　　引数は、CE, WR, CLK, DATAの順に設定します。
　　SETIOメソッドを実行しなかった場合は、デフォルト設定が使用されます。
　　　　CE : 14(B14)
       WR : 15(B15)
       CLK : 16(E5 )
       DATA 17(E6 )
　なお、MachiKania type Mで液晶版Xeviousモドキ<http://www.ze.em-net.ne.jp/~kenken/machikania/typem.html#xevious>
　を動作させる際に、液晶表示の反転が必要な場合は、I/Oが重複する場合がありますので、SETIOメソッドを使ってI/Oの
　設定を変更してください。

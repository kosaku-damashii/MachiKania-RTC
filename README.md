# MachiKania-RTC
RTC Class for MachiKania type M

電気二重層コンデンサ(1.5F)を使って144時間(=６日間)RTCを動作させることが出来ます。

ハードウェアの作成は、実態配線図(ActualWiringDiagram.jpg)を参照してください。 
実態配線図だと表面と裏面の配線が見辛いので、詳しくは、PasS( http://uaubn.g2.xrea.com/pass/ )で作成した実態配線図( MachiKania RTC.pas )を参照して下さい。
RTCクラスの前半に、サンプルコードが書かれていますので参考にしてください。

v0.1からの変更点
- I/Oの設定を、NEW関数の引数で必ず指定するように変更しました。
　(INITメソッドがNEW関数実行時に呼び出されることを認識しておらず、常にデフォルトのI/Oに戻っていました。そもそもデフォルトのI/O設定というものが意味がなく、必ず指定する必要があるため、NEW関数の引数で指定することにしました）
- SETIOメソッドの引数の並びを変更しました。
   CE, WR, CLK, DATA → CE, WR, DATA, CLK
   NEWメソッドの引数のI/O設定部分の並びもSETIOメソッドと同じになっています。
   v0.1のRTCクラスを使われていた方は変更が必要ですのでご注意ください。
- 年月日を設定するSETTMメソッドを追加しました。RTCに年月日が設定されていない状態の場合は、このSETTMメソッドを使って設定してください。

注意点
- WAITuメソッドを、TIMER割り込みを使用する方法ではなく、FORループで待つようにしたため、REMで該当箇所はコメントアウトしました。
もし、TIMER割り込みを使う方法を使用する場合は、REMで無効にしてあるコードに差し替えてください。
- MachiKania type Mで液晶版Xeviousモドキhttp://www.ze.em-net.ne.jp/~kenken/machikania/typem.html#xevious を動作させる際に、液晶表示の反転が必要な場合は、I/Oが重複する場合があります。便宜I/Oの設定を変更してください。

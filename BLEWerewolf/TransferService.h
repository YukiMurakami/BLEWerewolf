//
//  TransferService.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/31.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#pragma once

#define TRANSFER_SERVICE_UUID           @"9C67274B-A925-4B56-B3E7-A7E02D8CCB71"
#define TRANSFER_CHARACTERISTIC_UUID    @"D4C3A985-1A0D-448D-900E-7A6AA521AC07"



typedef NS_ENUM(NSInteger,SignalKind) {
    SignalKindGlobal,
    SignalKindNormal,
    SignalKindReceived,
};




/*
通信用プロトコル 2種類
・グローバル通知（宛先が不明な時に使用　具体的にはゲーム部屋通知）
・個人宛に通知
・受信完了通知
 
グローバル以外はペリフェラル側から送信するものと、セントラル側から送信するの２セットある

ペリフェラル→セントラルは基本的にnotificationを送信することで行う
セントラル→ペリフェラルは基本的にwrite動作で行う

<Peripheral側only>
------------全体外部に通知（ゲーム参加登録に使う）----------------------
「基本的に送りっぱなし（停止メソッドを呼ぶまで一定間隔で送信し続ける）」
「0:message」の形式で送信する
・ゲーム部屋のID通知「serveId:NNNNNN/S...S」 NNNNNNは６桁のゲームID（部屋生成時に自動的に生成）、S...Sはユーザ名
 
 
------------個人宛に通知------------
「受信完了通知を受け取るまで定期的に送信する（タイムアウト時間を設定し、それを過ぎたら無条件で送信をやめる」
「1:NNNNNN:T..T:A..A:message」の形式で送信する（NNNNNNはゲームID,T..TはシグナルID,A..Aは送り先ID）
・ゲーム参加了承「participateAllow:」

 
<Central側only>
 ------------個人宛に通知------------
「ペリフェラルにメッセージを送信する」（タイムアウト or ペリフェラルから受信通知を受け取るまで一定間隔で送信）
「1:NNNNNN:T..T:A..A:message」A..Aは送り元
 

<Peripheral、Centralで共通>
--------受信完了通知--------
「タイムアウト時間を過ぎるまで無条件で一定間隔で送信し続ける」
「2:NNNNNN:T..T」(T..Tは受け取ったsignalId)

*/
/*
ゲームの参加

・ゲーム部屋に参加要求「participateRequest:NNNNNN/A..A/S...S」NNNNNNは６桁のゲームID、A..Aは32桁の端末識別文字列（初回起動時に自動生成）S...Sはユーザ名

・ゲーム参加者を通知（一度に送れる情報が限られるので一人ずつおくり、確認をとる）「member:0/A..A/S..S/12」 0はプレイヤーID 12は参加人数
・ゲーム参加者確認通知 「memberCheck:A..A」A..Aは送り元
・ルール設定を通知「setting:/6,3,1,1,1,1/7,3,0,1,1」一つ目は配役、二つ目はルール（昼時間、夜時間、占いモード、連続護衛、役かけ）
・ルール確認（ゲーム開始了承）を通知「settingCheck:A..A」
ゲーム開始
・ゲーム開始を通知（役職通知）「gamestart:0,0/1,0/.../8,1」プレイヤーID,役職Idのセットを人数分用意
・役職確認完了通知「roleCheck:A..A」
・全員分の役職確認通知を回収後、初日夜を通知「firstNight:」
 基本的にブロードキャスト的な送信を行う（全体に宛先を書いたメッセージを送信し、受信側（セントラル）で取捨選択を行う）
 
 
チャット
・チャット送信（central->peripheral)「chatsend:A..A/T...T」T...Tは内容
・チャット受信（peripheral->central)「chatreceive:A..A/T...T」
・GMメッセージ（peripheral(gm)->central）「chatreceive:G..G/A..A/T..T」G..GはgmId
 
役職アクション
・「action:1/0/3」1は役職ID、0は実行者、3は対象者
*/
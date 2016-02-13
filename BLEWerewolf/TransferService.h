//
//  TransferService.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/31.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#pragma once


typedef NS_ENUM(NSInteger,SignalKind) {
    SignalKindGlobal,
    SignalKindNormal,
    SignalKindReceived,
};

//ゲームオーバーになったプレイヤーは天国背景を表示してゲーム終了まで放置する
//ただしペリフェラル担当のプレイヤーはゲーム進行に必要な動作は行う

/*
通信用プロトコル 2種類
(A) "advertiseMyDevice:<gameId>:<peripheralId>:<peripheralName>" 自分のIDを不特定多数の全員に知らせる (ペリフェラルのみ）
 ・セントラルはこの信号を受信し、自分のperipheralIDとして保持
 ・セントラルはペリフェラルを保持したら自分のIDを送信する（ペリフェラルはこのメッセージのみは無条件で受信し、セントラルIDとして保持しておく。今後は自分の担当セントラルのメッセージしか受信しない）
メッセージタイプは"centrals"
 
(B) "mes:<signalId>:<yourId>:<myId>:<message>" yourIDに対してメッセージを送信する
 ・送られるメッセージはすべて個別idを付与して送る（2重受信の防止)
 ・送り出すメッセージはその都度idをインクリメントする
 ・yourIdが"centrals"だった場合は、セントラルはすべて受信
基本的にはこの２つ
タイムアウトとか受信応答とかは今回は保留（５０個目のメッセージを送信するときから、はじめのメモリが解放され、このときに通信が終わる）
メッセージは"<yourId>" or "centrals"
 

基本的にブロードキャスト的な送信を行う（全体に宛先を書いたメッセージを送信し、受信側（セントラル）で取捨選択を行う）
 
 
今のとこは最大接続台数が不明なため、サブサーバは置かない
 

<Peripheral側only>
・ゲーム参加了承「participateAllow:」
・（同期必須）ゲーム参加者を通知（一度に送れる情報が限られるので一人ずつおくり、確認をとる）「member:0/C..C/S..S/12」 0はプレイヤーID 12は参加人数
・ルール設定を通知「setting:/6,3,1,1,1,1/7,3,0,1,1」一つ目は配役、二つ目はルール（昼時間、夜時間、占いモード、連続護衛、役かけ）
・ゲーム開始を通知（役職通知）「gamestart:0,0/1,0/.../8,1」プレイヤーID,役職Idのセットを人数分用意
・全員分の役職確認通知を回収後、初日夜を通知「firstNight:」
・チャット（peripheral->central)「chatreceive:A..A/M...M」M...Mは内容
・GMメッセージ（peripheral(gm)->central）「chatreceive:G..G/A..A/T..T」G..GはgmId
・朝開始＋犠牲者通知「afternoonStart:2,4」数値は犠牲者のプレイヤーID
・全員の犠牲者受信完了を通知「victimCheckFinish:」
・投票結果通知「voteResult:1/-1/0,0,1/1,5,2/2,8,0/.../8,1,1」何回目の投票か、最多得票者、投票内訳(投票者、投票先、投票者に何票はいったか)の順番（最多得票者が-1の場合は決戦orランダム、生存者分のみ)
・夜開始を通知「nightStart:」
・夜時間開始前に道連れを通知「afternoonVictim:1,8/2,?」プレイヤーID,死因となる役職IDのセットを死亡者分
・ゲーム終了を通知「gameEnd:W」Wは処理者チームID (utilityを参照）


 
<Central側only>
・ゲーム部屋に参加要求「participateRequest:NNNNNN/C..C/S...S/P..P/F」NNNNNNは６桁のゲームID、C..Cは16桁の端末識別文字列（初回起動時に自動生成）S...Sはユーザ名,P..Pは接続先ペリフェラルID,Fは普通のセントラルなら0,サブサーバなら1
・ゲーム部屋から退出通知（タイムアウトなど）「participateCancel:NNNNNN/C..C」
・参加者情報受信完了通知「memberCheck:C..C」
・ルール確認（ゲーム開始了承）を通知「settingCheck:A..A」
・役職確認完了通知「roleCheck:A..A」
・役職アクションを実行「action:1/0/3」1は役職ID、0は実行者、3は対象者
・チャット（central->peripheral)「chatsend:A..A/M...M」M...Mは内容
・夜時間終了を通知「nightFinish:A..A」
・投票結果確認通知「checkVoting:A..A」
・夜直前の道連れ確認通知「afternoonVictimCheck:C..C」
・犠牲者確認通知「checkVictim:A..A」

 
*/
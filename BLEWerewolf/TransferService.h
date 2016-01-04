//
//  TransferService.h
//  BLEWerewolf
//
//  Created by Yuki Murakami on 2015/07/31.
//  Copyright (c) 2015年 yuki. All rights reserved.
//

#ifndef BLEWerewolf_TransferService_h
#define BLEWerewolf_TransferService_h

#define TRANSFER_SERVICE_UUID           @"9C67274B-A925-4B56-B3E7-A7E02D8CCB71"
#define TRANSFER_CHARACTERISTIC_UUID    @"D4C3A985-1A0D-448D-900E-7A6AA521AC07"

#endif

//通信用プロトコル
/*
ゲームの参加
・ゲーム部屋のID通知「serveId:NNNNNN/S...S」 NNNNNNは６桁のゲームID（部屋生成時に自動的に生成）、S...Sはユーザ名
・ゲーム部屋に参加要求「participateRequest:NNNNNN/A..A/S...S」NNNNNNは６桁のゲームID、A..Aは32桁の端末識別文字列（初回起動時に自動生成）S...Sはユーザ名
・ゲーム参加了承「participateAllow:A..A」A..Aは32桁の端末識別文字列
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
*/
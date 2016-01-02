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
・ルール設定を通知「setting:/6,3,1,1,1,1/7,3,0,1,1」一つ目は配役、二つ目はルール（昼時間、夜時間、占いモード、連続護衛、役かけ）
・ルール確認（ゲーム開始了承）を通知「settingCheck:A..A」
・ゲーム開始を通知（役職通知）「gamestart:A..A,S..S,0,0/A..A,S..S,1,0/.../A..A,S..S,8,1」識別ID,名前,プレイヤーID,役職Idのセットを人数分用意
 基本的にブロードキャスト的な送信を行う（全体に宛先を書いたメッセージを送信し、受信側（セントラル）で取捨選択を行う）
*/
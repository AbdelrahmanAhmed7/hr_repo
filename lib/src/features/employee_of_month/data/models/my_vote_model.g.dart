// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_vote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyVoteModel _$MyVoteModelFromJson(Map<String, dynamic> json) => MyVoteModel(
  hasVoted: json['hasVoted'] as bool,
  nomineeUserId: json['nomineeUserId'] as String?,
  nomineeName: json['nomineeName'] as String?,
);

Map<String, dynamic> _$MyVoteModelToJson(MyVoteModel instance) =>
    <String, dynamic>{
      'hasVoted': instance.hasVoted,
      'nomineeUserId': instance.nomineeUserId,
      'nomineeName': instance.nomineeName,
    };

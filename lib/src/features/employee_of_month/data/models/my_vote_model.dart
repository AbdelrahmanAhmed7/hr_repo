import 'package:json_annotation/json_annotation.dart';

part 'my_vote_model.g.dart';

@JsonSerializable()
class MyVoteModel {
  final bool hasVoted;
  final String? nomineeUserId;
  final String? nomineeName;

  const MyVoteModel({
    required this.hasVoted,
    this.nomineeUserId,
    this.nomineeName,
  });

  factory MyVoteModel.fromJson(Map<String, dynamic> json) =>
      _$MyVoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$MyVoteModelToJson(this);
}

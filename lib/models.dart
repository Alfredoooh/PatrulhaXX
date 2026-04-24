class VideoItem {
  final String title;
  final String thumb;
  final String videoUrl;
  final String duration;
  final String views;
  final String source;

  const VideoItem({
    required this.title,
    required this.thumb,
    required this.videoUrl,
    required this.duration,
    required this.views,
    required this.source,
  });
}

const Map<String, String> kBadges = {
  'eporner': 'EP', 'pornhub': 'PH', 'redtube': 'RT', 'youporn': 'YP',
  'xvideos': 'XV', 'xhamster': 'XH', 'spankbang': 'SB', 'bravotube': 'BT',
  'drtuber': 'DT', 'txxx': 'TX', 'gotporn': 'GP', 'porndig': 'PD',
  'tnaflix': 'TN', 'empflix': 'EF', 'porntrex': 'PTX', 'hclips': 'HC',
  'tubedupe': 'TD', 'sexvid': 'SV', 'nuvid': 'NV', 'sunporno': 'SP',
  'pornone': 'P1', 'beeg': 'BG', 'slutload': 'SL', 'tube8': 'T8', 'iceporn': 'IC',
  'vjav': 'VJ', 'jizzbunker': 'JB', 'yeptube': 'YT', 'cliphunter': 'CH',
};

const Map<String, String> kLabels = {
  'eporner': 'Eporner', 'pornhub': 'Pornhub', 'redtube': 'RedTube', 'youporn': 'YouPorn',
  'xvideos': 'XVideos', 'xhamster': 'xHamster', 'spankbang': 'SpankBang', 'bravotube': 'BravoTube',
  'drtuber': 'DrTuber', 'txxx': 'TXXX', 'gotporn': 'GotPorn', 'porndig': 'PornDig',
  'tnaflix': 'TNAFlix', 'empflix': 'EmpFlix', 'porntrex': 'PornTrex', 'hclips': 'HClips',
  'tubedupe': 'TubeDupe', 'sexvid': 'SexVid', 'nuvid': 'Nuvid', 'sunporno': 'SunPorno',
  'pornone': 'PornOne', 'beeg': 'Beeg', 'slutload': 'SlutLoad', 'tube8': 'Tube8', 'iceporn': 'IcePorn',
  'vjav': 'vJav', 'jizzbunker': 'JizzBunker', 'yeptube': 'YepTube', 'cliphunter': 'ClipHunter',
};

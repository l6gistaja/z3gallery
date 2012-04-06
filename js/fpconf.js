var fpConf = {
   dirVideo: 'v/', //subdirectory which contains videos
   dirPlayer: 'flowplayer/', //subdirectory which contains (flow)player SWFs
   playerPage: 'flashplayer.html', //HTML page which plays videos
   staticListing: 'index.html',  //data file from which vidRegexp tries to get videofiles
   vidRegexp: /[a-z\d\.\-_]+\.(flv|f4v|mp4)/igm,
   thumbnail_directory: 'g/', // thumbnail directory; if '' then thumbnail arent available
   thumbnail_extension: '.png', // will be added to the end of video file name
   thumbnail_height: 120,
   thumbnail_width: 160,
}

// HTTP GET request defaults
var GetRequest = {
   l: 0, // loop through playlist ( 1 for true)
   h: 300, // player height
   w: 425, // player width
   m: 1.0, // player zoom
   f: '', // default file to play; if '' then none
   
}
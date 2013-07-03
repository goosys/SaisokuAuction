
$(document).ready(function(){

  $('.entry article .location').each(function(){
    $(this).text( $(this).text().replace(/ .+$/,'') );
    $(this).addClass('badge badge-inverse');
  });
  
  $('.entry article .price').each(function(){
    $(this).text( $(this).text().replace(/\.\w+$/,'円') );
    $(this).prepend( $('<label>　現在価格　</label>').addClass('badge badge-important') );
  })
  $('.entry article .initprice').each(function(){
    $(this).text( $(this).text().replace(/\.\w+$/,'円') );
    $(this).prepend( $('<label>　開始価格　</label>').addClass('badge badge-warning') );
  });
  $('.entry article .initprice label,.entry article .price label').after( $('<br>') );
  
  var now = new Date();
  $('.entry article .endtime').each(function(){
    var tm = new Date($(this).text());
    var rem = remain(tm,now);
    $(this).html( rem ).attr('title',tm.toString());
  });
  
  $('article:gt(7)','.entry').css('display','none');

});

function remain( endtime, now ) {
	var msec = endtime.getTime() - now.getTime() ;
	
	if( msec<=0 ) { return "このオークションは終了しました"; }
	if( (msec/=1000) < 60) {
		return "あと <em class=\"second\">" + Math.floor(msec)+ "<\/em>" + " 秒";
	}else if( (msec/=60) < 60) {
		return "あと <em class=\"minute\">" + Math.floor(msec)+ "<\/em>" + " 分";
	}else if ( (msec/=60) < 24){
		return "あと <em class=\"hour\">" + Math.floor(msec)+ "<\/em>" + " 時間";
	}else{
		return "あと <em class=\"day\">" + Math.floor(msec/24)+ "<\/em>" + " 日";
	}
}


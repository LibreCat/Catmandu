package Dancer::Plugin::Tracker;

our $VERSION = '0.1';

use strict;
use warnings;
use Dancer::Plugin;
use Dancer qw(:syntax);

my $setting = plugin_setting;
my $tracker = $setting->{tracker} || 'ga';
my $tracker_js;

if ($tracker eq 'ga') {
    my $tracker_js = <<JS;
var _gaq = _gaq || [];
_gaq.push(['_setAccount', '$setting->{account_id}']);
_gaq.push(['_trackPageview']);
(function() {
    var ga=document.createElement('script');ga.type='text/javascript';ga.async=true;
    ga.src=('https:' == document.location.protocol ? 'https://ssl' : 'http://www')+'.google-analytics.com/ga.js';
    var s=document.getElementsByTagName('script')[0];s.parentNode.insertBefore(ga,s);
})();
JS
} else {
    $tracker_js = <<JS;
var _paq = _paq || [];
(function(){
    var u=(("https:" == document.location.protocol) ? "https://$setting->{url}/" : "http://$setting->{url}/");
    _paq.push(['setSiteId', $setting->{site_id}]);
    _paq.push(['setTrackerUrl', u+'piwik.php']);
    _paq.push(['trackPageView']);
    var d=document,
        g=d.createElement('script'),
        s=d.getElementsByTagName('script')[0];
    g.type='text/javascript';g.defer=true;g.async=true;g.src=u+'piwik.js';
    s.parentNode.insertBefore(g,s);
})();
JS
}

my $tracker_script = <<HTML;
<script type="text/javascript">
$tracker_js
</script>
HTML

hook before_template => sub {
    $_[0]->{tracker} = $tracker;
    $_[0]->{tracker_js} = $tracker_js;
    $_[0]->{tracker_script} = $tracker_script;
};

register_plugin;

1;


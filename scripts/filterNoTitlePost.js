hexo.extend.filter.register('before_post_render', function(data) {
    if (!data.title) {
        return false;
    }
    return data;
});
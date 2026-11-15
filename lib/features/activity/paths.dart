const activityPath = '/activity';

/// Activity narrowed to the movements in or out of one paddock.
String paddockActivityPath(String paddockId) =>
    Uri(path: activityPath, queryParameters: {'paddock': paddockId}).toString();

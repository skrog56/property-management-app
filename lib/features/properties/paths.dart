const propertiesPath = '/properties';

String propertyPath(String propertyId) => '$propertiesPath/$propertyId';

String paddockPath(String propertyId, String paddockId) =>
    '${propertyPath(propertyId)}/paddocks/$paddockId';

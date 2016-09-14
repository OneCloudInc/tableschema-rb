require 'spec_helper'

describe JsonTableSchema::Types do

  describe JsonTableSchema::Types::String do

    let(:field) {
      {
        'name' => 'Name',
        'type' => 'string',
        'format' => 'default',
        'constraints' => {
          'required' => true
        }
      }
    }

    let(:type) { JsonTableSchema::Types::String.new(field) }

    it 'casts a simple string' do
      value = 'a string'
      expect(type.cast(value)).to eq('a string')
    end

    it 'returns an error if the value is not a string' do
      value = 1
      expect { type.cast(value) }.to raise_error(JsonTableSchema::InvalidCast)
    end

    context 'emails' do

      let(:email_field) {
        field['format'] = 'email'
        field
      }

      let(:email_type) { JsonTableSchema::Types::String.new(email_field) }

      it 'casts an email' do
        value = 'test@test.com'
        expect(email_type.cast(value)).to eq(value)

        value = '\$A12345@example.com'
        expect(email_type.cast(value)).to eq(value)

        value = '!def!xyz%abc@example.com'
        expect(email_type.cast(value)).to eq(value)
      end

      it 'fails with an invalid email' do
        value = 1
        expect { email_type.cast(value) }.to raise_error(JsonTableSchema::InvalidCast)

        value = 'notanemail'
        expect { email_type.cast(value) }.to raise_error(JsonTableSchema::InvalidEmail)
      end

    end

    context 'uris' do

      let(:uri_field) {
        field['format'] = 'uri'
        field
      }

      let(:uri_type) { JsonTableSchema::Types::String.new(uri_field) }

      it 'casts a uri' do
        value = 'http://test.com'
        expect(uri_type.cast(value)).to eq(value)
      end

      it 'raises an expection for an invalid URI' do
        value = 'notauri'
        expect { uri_type.cast(value) }.to raise_error(JsonTableSchema::InvalidURI)
      end

    end

    context 'uuid' do

      let(:uuid_field) {
        field['format'] = 'uuid'
        field
      }

      let(:uuid_type) { JsonTableSchema::Types::String.new(uuid_field) }

      it 'casts a uuid' do
        value = '12345678123456781234567812345678'
        expect(uuid_type.cast(value)).to eq(value)

        value = 'urn:uuid:12345678-1234-5678-1234-567812345678'
        expect(uuid_type.cast(value)).to eq(value)

        value = '123e4567-e89b-12d3-a456-426655440000'
        expect(uuid_type.cast(value)).to eq(value)
      end

      it 'raises for invalid uuids' do
        value = '1234567812345678123456781234567?'
        expect { uuid_type.cast(value) }.to raise_error(JsonTableSchema::InvalidUUID)

        value = '1234567812345678123456781234567'
        expect { uuid_type.cast(value) }.to raise_error(JsonTableSchema::InvalidUUID)

        value = 'X23e4567-e89b-12d3-a456-426655440000'
        expect { uuid_type.cast(value) }.to raise_error(JsonTableSchema::InvalidUUID)
      end

    end

  end

  describe JsonTableSchema::Types::Number do

    let(:field) {
      {
        'name' => 'Name',
        'type' => 'number',
        'format' => 'default',
        'constraints' => {
          'required' => true
        }
      }
    }

    let(:type) { JsonTableSchema::Types::Number.new(field) }

    it 'casts a simple number' do
      value = '10.00'
      expect(type.cast(value)).to eq(Float('10.00'))
    end

    it 'casts when the value is already cast' do
      [1, 1.0, Float(1)].each do |value|
        ['default', 'currency'].each do |format|
          field['format'] = format
          type = JsonTableSchema::Types::Number.new(field)
          expect(type.cast(value)).to eq(Float(value))
        end
      end
    end

    it 'returns an error if the value is not a number' do
      value = 'string'
      expect { type.cast(value) }.to raise_error(JsonTableSchema::InvalidCast)
    end

    it 'casts with localized settings' do
      [
        '10,000.00',
        '10,000,000.23',
        '10.23',
        '1,000',
        '100%',
        '1000‰'
      ].each do |value|
        expect { type.cast(value) }.to_not raise_error
      end

      field['groupChar'] = '#'
      type = JsonTableSchema::Types::Number.new(field)

      [
        '10#000.00',
        '10#000#000.23',
        '10.23',
        '1#000'
      ].each do |value|
        expect { type.cast(value) }.to_not raise_error
      end

      field['decimalChar'] = '@'
      type = JsonTableSchema::Types::Number.new(field)

      [
        '10#000@00',
        '10#000#000@23',
        '10@23',
        '1#000'
      ].each do |value|
        expect { type.cast(value) }.to_not raise_error
      end

    end

    context 'currencies' do

      let(:currency_field) {
        field['format'] = 'currency'
        field
      }

      let(:currency_type) {
        JsonTableSchema::Types::Number.new(currency_field)
      }

      it 'casts successfully' do
        [
          '10,000.00',
          '10,000,000.00',
          '$10000.00',
          '  10,000.00 €',
        ].each do |value|
          expect { currency_type.cast(value) }.to_not raise_error
        end

        field['decimalChar'] = ','
        field['groupChar'] = ' '
        currency_type = JsonTableSchema::Types::Number.new(currency_field)

        [
          '10 000,00',
          '10 000 000,00',
          '10000,00 ₪',
          '  10 000,00 £',
        ].each do |value|
          expect { currency_type.cast(value) }.to_not raise_error
        end
      end

      it 'returns an error with a currency and a duff format' do
        value1 = '10,000a.00'
        value2 = '10+000.00'
        value3 = '$10:000.00'

        expect { currency_type.cast(value1) }.to raise_error(JsonTableSchema::InvalidCast)
        expect { currency_type.cast(value2) }.to raise_error(JsonTableSchema::InvalidCast)
        expect { currency_type.cast(value3) }.to raise_error(JsonTableSchema::InvalidCast)
      end

    end

  end

  describe JsonTableSchema::Types::Integer do

    let(:field) {
      {
        'name' => 'Name',
        'type' => 'integer',
        'format' => 'default',
        'constraints' => {
          'required' => true
        }
      }
    }

    let(:type) { JsonTableSchema::Types::Integer.new(field) }

    it 'casts a simple integer' do
      value = '1'
      expect(type.cast(value)).to eq(1)
    end

    it 'raises when the value is not an integer' do
      value = 'string'
      expect { type.cast(value) }.to raise_error(JsonTableSchema::InvalidCast)
    end

    it 'casts when value is already cast' do
      value = 1
      expect(type.cast(value)).to eq(1)
    end

  end

  describe JsonTableSchema::Types::Boolean do

    let(:field) {
      {
        'name' => 'Name',
        'type' => 'boolean',
        'format' => 'default',
        'constraints' => {
          'required' => true
        }
      }
    }

    let(:type) { JsonTableSchema::Types::Boolean.new(field) }

    it 'casts a simple true value' do
      value = 't'
      expect(type.cast(value)).to be true
    end

    it 'casts a simple false value' do
      value = 'f'
      expect(type.cast(value)).to be false
    end

    it 'casts truthy values' do
      ['yes', 1, 't', 'true', true].each do |value|
        expect(type.cast(value)).to be true
      end
    end

    it 'casts falsy values' do
      ['no', 0, 'f', 'false', false].each do |value|
        expect(type.cast(value)).to be false
      end
    end

    it 'raises for invalid values' do
      value = 'not a true value'
      expect { type.cast(value) }.to raise_error(JsonTableSchema::InvalidCast)

      value = 11231902333
      expect { type.cast(value) }.to raise_error(JsonTableSchema::InvalidCast)
    end

  end

  describe JsonTableSchema::Types::Null do

    let(:field) {
      {
        'name' => 'Name',
        'type' => 'boolean',
        'format' => 'default',
        'constraints' => {
          'required' => true
        }
      }
    }

    let(:type) { JsonTableSchema::Types::Null.new(field) }

    it 'casts simple values' do
      value = 'null'
      expect(type.cast(value)).to be nil

      value = 'null'
      expect(type.cast(value)).to be nil

      value = 'none'
      expect(type.cast(value)).to be nil

      value = 'nil'
      expect(type.cast(value)).to be nil

      value = 'nan'
      expect(type.cast(value)).to be nil

      value = '-'
      expect(type.cast(value)).to be nil

      value = ''
      expect(type.cast(value)).to be nil
    end

    it 'raises for non null values' do
      value = 'nothing'
      expect { type.cast(value) }.to raise_error(JsonTableSchema::InvalidCast)
    end

  end


end

#
#
# class TestObject(base.BaseTestCase):
#     def setUp(self):
#         super(TestObject, self).setUp()
#         self.field = {
#             'name': 'Name',
#             'type': 'object',
#             'format': 'default',
#             'constraints': {
#                 'required': True
#             }
#         }
#
#     def test_dict(self):
#         value = {'key': 'value'}
#         _type = types.ObjectType(self.field)
#
#         self.assertDictEqual(_type.cast(value), value)
#
#     def test_json_string(self):
#         value = '{"key": "value"}'
#         _type = types.ObjectType(self.field)
#
#         self.assertDictEqual(_type.cast(value), {'key': 'value'})
#
#     def test_invalid(self):
#         value = ['boo', 'ya']
#         _type = types.ObjectType(self.field)
#
#         self.assertRaises(exceptions.InvalidObjectType, _type.cast, value)
#
#
# class TestArray(base.BaseTestCase):
#     def setUp(self):
#         super(TestArray, self).setUp()
#         self.field = {
#             'name': 'Name',
#             'type': 'array',
#             'format': 'default',
#             'constraints': {
#                 'required': True
#             }
#         }
#
#     def test_array_type_simple_true(self):
#         value = ['1', '2']
#         _type = types.ArrayType(self.field)
#         self.assertEquals(_type.cast(value), value)
#
#     def test_array_type_simple_json_string(self):
#         value = '["1", "2"]'
#         _type = types.ArrayType(self.field)
#         self.assertEquals(_type.cast(value), [u'1', u'2'])
#
#     def test_array_type_simple_false(self):
#         value = 'string, string'
#         _type = types.ArrayType(self.field)
#         self.assertRaises(exceptions.InvalidArrayType, _type.cast, value)
#
#
# class TestDate(base.BaseTestCase):
#     def setUp(self):
#         super(TestDate, self).setUp()
#         self.field = {
#             'name': 'Name',
#             'type': 'date',
#             'format': 'default',
#             'constraints': {
#                 'required': True
#             }
#         }
#
#     def test_date_from_string_iso_format(self):
#         value = '2019-01-01'
#         _type = types.DateType(self.field)
#
#         self.assertEquals(_type.cast(value), date(2019, 1, 1))
#
#     def test_date_type_any_true(self):
#         value = '10th Jan 1969'
#         self.field['format'] = 'any'
#         _type = types.DateType(self.field)
#
#         self.assertEquals(_type.cast(value), date(1969, 1, 10))
#
#     def test_date_type_fmt(self):
#
#         value = '10/06/2014'
#         self.field['format'] = 'fmt:%d/%m/%Y'
#         _type = types.DateType(self.field)
#
#         self.assertEquals(_type.cast(value), date(2014, 6, 10))
#
#     def test_date_type_fmt_stripping_bug(self):
#
#         value = '2014-06'
#         self.field['format'] = 'fmt:%Y-%m'
#         _type = types.DateType(self.field)
#
#         self.assertEquals(_type.cast(value), date(2014, 6, 1))
#
#     def test_non_iso_date_fails_for_default(self):
#         value = '01-01-2019'
#         _type = types.DateType(self.field)
#
#         self.assertRaises(exceptions.InvalidDateType, _type.cast, value)
#
#     def test_date_type_any_parser_fail(self):
#         value = '10th Jan nineteen sixty nine'
#         self.field['format'] = 'any'
#         _type = types.DateType(self.field)
#
#         self.assertRaises(exceptions.InvalidDateType, _type.cast, value)
#
#     def test_invalid_fmt(self):
#         value = '2014/12/19'
#         self.field['type'] = 'fmt:DD/MM/YYYY'
#         _type = types.DateType(self.field)
#
#         self.assertRaises(exceptions.InvalidDateType, _type.cast, value)
#
#     def test_valid_fmt_invalid_value(self):
#         value = '2014/12/19'
#         self.field['type'] = 'fmt:%m/%d/%y'
#         _type = types.DateType(self.field)
#
#         self.assertRaises(exceptions.InvalidDateType, _type.cast, value)
#
#     def test_date_type_with_already_cast_value(self):
#         for value in [date(2015, 1, 1)]:
#             for format in ['default', 'any', 'fmt:%Y-%m-%d']:
#                 self.field['format'] = format
#                 _type = types.DateType(self.field)
#                 self.assertEqual(_type.cast(value), value)
#
#
# class TestTime(base.BaseTestCase):
#     def setUp(self):
#         super(TestTime, self).setUp()
#         self.field = {
#             'name': 'Name',
#             'type': 'time',
#             'format': 'default',
#             'constraints': {
#                 'required': True
#             }
#         }
#
#     def test_time_type_default(self):
#         value = '06:00:00'
#         _type = types.TimeType(self.field)
#         self.assertEquals(_type.cast(value), time(6))
#
#     def test_time_type_non_iso_raises_error(self):
#         value = '3 am'
#         _type = types.TimeType(self.field)
#         self.assertRaises(exceptions.InvalidTimeType, _type.cast, value)
#
#     def test_time_type_parsing(self):
#         value = '3:00 am'
#         self.field['format'] = 'any'
#         _type = types.TimeType(self.field)
#         self.assertEquals(_type.cast(value), time(3))
#
#     def test_time_type_format(self):
#         value = '3:00'
#         self.field['format'] = 'fmt:%H:%M'
#         _type = types.TimeType(self.field)
#         self.assertEquals(_type.cast(value), time(3))
#
#     def test_time_invalid_type_format(self):
#         value = 3.00
#         self.field['format'] = 'fmt:any'
#         _type = types.TimeType(self.field)
#         self.assertRaises(exceptions.InvalidTimeType, _type.cast, value)
#
#         value = {}
#         _type = types.TimeType(self.field)
#         self.assertRaises(exceptions.InvalidTimeType, _type.cast, value)
#
#         value = []
#         _type = types.TimeType(self.field)
#         self.assertRaises(exceptions.InvalidTimeType, _type.cast, value)
#
#     def test_time_type_with_already_cast_value(self):
#         for value in [time(12, 0, 0)]:
#             for format in ['default', 'any', 'fmt:any']:
#                 self.field['format'] = format
#                 _type = types.TimeType(self.field)
#                 self.assertEqual(_type.cast(value), value)
#
#
# class TestDateTime(base.BaseTestCase):
#     def setUp(self):
#         super(TestDateTime, self).setUp()
#         self.field = {
#             'name': 'Name',
#             'type': 'datetime',
#             'format': 'default',
#             'constraints': {
#                 'required': True
#             }
#         }
#
#     def test_valid_iso_datetime(self):
#         value = '2014-01-01T06:00:00Z'
#         _type = types.DateTimeType(self.field)
#         self.assertEquals(_type.cast(value), datetime(2014, 1, 1, 6))
#
#     def test_any_parser_guessing(self):
#         value = '10th Jan 1969 9 am'
#         self.field['format'] = 'any'
#         _type = types.DateTimeType(self.field)
#         self.assertEquals(_type.cast(value), datetime(1969, 1, 10, 9))
#
#     def test_specified_format(self):
#         value = '21/11/06 16:30'
#         self.field['format'] = 'fmt:%d/%m/%y %H:%M'
#         _type = types.DateTimeType(self.field)
#         self.assertEquals(_type.cast(value), datetime(2006, 11, 21, 16, 30))
#
#     def test_non_iso_datetime_fails_for_default(self):
#         value = 'Mon 1st Jan 2014 9 am'
#         _type = types.DateTimeType(self.field)
#         self.assertRaises(exceptions.InvalidDateTimeType, _type.cast, value)
#
#     def test_unparsable_date_raises_exception(self):
#         value = 'the land before time'
#         self.field['format'] = 'any'
#         _type = types.DateTimeType(self.field)
#         self.assertRaises(exceptions.InvalidDateTimeType, _type.cast, value)
#
#     def test_invalid_date_format(self):
#         value = '21/11/06 16:30'
#         self.field['format'] = 'fmt:notavalidformat'
#         _type = types.DateTimeType(self.field)
#         self.assertRaises(exceptions.InvalidDateTimeType, _type.cast, value)
#
#     def test_datetime_type_with_already_cast_value(self):
#         for value in [datetime(2015, 1, 1, 12, 0, 0)]:
#             for format in ['default', 'any', 'fmt:any']:
#                 self.field['format'] = format
#                 _type = types.DateTimeType(self.field)
#                 self.assertEqual(_type.cast(value), value)
#
#
# class TestGeoPoint(base.BaseTestCase):
#     def setUp(self):
#         super(TestGeoPoint, self).setUp()
#         self.field = {
#             'name': 'Name',
#             'type': 'geopoint',
#             'format': 'default',
#             'constraints': {
#                 'required': True
#             }
#         }
#
#     def test_geopoint_type_simple_true(self):
#         value = '10.0, 21.00'
#         _type = types.GeoPointType(self.field)
#         self.assertEquals(_type.cast(value), [Decimal(10.0), Decimal(21)])
#
#     def test_values_outside_longitude_range(self):
#         value = '310.0, 921.00'
#         _type = types.GeoPointType(self.field)
#         self.assertRaises(exceptions.InvalidGeoPointType, _type.cast, value)
#
#     def test_values_outside_latitude_range(self):
#         value = '10.0, 921.00'
#         _type = types.GeoPointType(self.field)
#         self.assertRaises(exceptions.InvalidGeoPointType, _type.cast, value)
#
#     def test_geopoint_type_simple_false(self):
#         value = 'this is not a geopoint'
#         _type = types.GeoPointType(self.field)
#         self.assertRaises(exceptions.InvalidGeoPointType, _type.cast, value)
#
#     def test_non_decimal_values(self):
#         value = 'blah, blah'
#         _type = types.GeoPointType(self.field)
#         self.assertRaises(exceptions.InvalidGeoPointType, _type.cast, value)
#
#     def test_wrong_length_of_points(self):
#         value = '10.0, 21.00, 1'
#         _type = types.GeoPointType(self.field)
#         self.assertRaises(exceptions.InvalidGeoPointType, _type.cast, value)
#
#     def test_array(self):
#         self.field['format'] = 'array'
#         _type = types.GeoPointType(self.field)
#         self.assertEquals(_type.cast('[10.0, 21.00]'),
#                           [Decimal(10.0), Decimal(21)])
#         self.assertEquals(_type.cast('["10.0", "21.00"]'),
#                           [Decimal(10.0), Decimal(21)])
#
#     def test_array_invalid(self):
#         self.field['format'] = 'array'
#         _type = types.GeoPointType(self.field)
#         self.assertRaises(exceptions.InvalidGeoPointType, _type.cast, '1,2')
#         self.assertRaises(exceptions.InvalidGeoPointType, _type.cast,
#                           '["a", "b"]')
#         self.assertRaises(exceptions.InvalidGeoPointType, _type.cast,
#                           '[1, 2, 3]')
#
#     def test_object(self):
#         self.field['format'] = 'object'
#         _type = types.GeoPointType(self.field)
#         self.assertEquals(_type.cast('{"longitude": 10.0, "latitude": 21.00}'),
#                           [Decimal(10.0), Decimal(21)])
#         self.assertEquals(
#             _type.cast('{"longitude": "10.0", "latitude": "21.00"}'),
#             [Decimal(10.0), Decimal(21)]
#         )
#
#     def test_array_object(self):
#         self.field['format'] = 'object'
#         _type = types.GeoPointType(self.field)
#         self.assertRaises(exceptions.InvalidGeoPointType, _type.cast, '[ ')
#         self.assertRaises(exceptions.InvalidGeoPointType, _type.cast,
#                           '{"blah": "10.0", "latitude": "21.00"}')
#         self.assertRaises(exceptions.InvalidGeoPointType, _type.cast,
#                           '{"longitude": "a", "latitude": "21.00"}')
#
#
# class TestGeoJson(base.BaseTestCase):
#     def setUp(self):
#         super(TestGeoJson, self).setUp()
#         self.field = {
#             'name': 'Name',
#             'type': 'geojson',
#             'format': 'default',
#             'constraints': {
#                 'required': False
#             }
#         }
#
#     def test_geojson_type(self):
#         value = {'coordinates': [0, 0, 0], 'type': 'Point'}
#         self.field['type'] = 'geojson'
#         _type = types.GeoJSONType(self.field)
#
#         self.assertRaises(exceptions.InvalidGeoJSONType, _type.cast, value)
#
#     def test_geojson_type_simple_true(self):
#         value = {
#             "properties": {
#                 "Ã": "Ã"
#             },
#             "type": "Feature",
#             "geometry": None,
#         }
#
#         self.field['type'] = 'geojson'
#         _type = types.GeoJSONType(self.field)
#
#         self.assertEquals(_type.cast(value), value)
#
#     def test_geojson_type_cast_from_string(self):
#         value = '{"geometry": null, "type": "Feature", "properties": {"\\u00c3": "\\u00c3"}}'
#         self.field['type'] = 'geojson'
#         _type = types.GeoJSONType(self.field)
#
#         self.assertEquals(_type.cast(value), {
#             "properties": {
#                 "Ã": "Ã"
#             },
#             "type": "Feature",
#             "geometry": None,
#         })
#
#     def test_geojson_type_simple_false(self):
#         value = ''
#         self.field['type'] = 'geojson'
#         _type = types.GeoJSONType(self.field)
#
#         # Required is false so cast null value to None
#         assert _type.cast(value) == None
#
#
# class TestNullValues(base.BaseTestCase):
#
#     none_string_types = {
#         'number': types.NumberType,
#         'integer': types.IntegerType,
#         'boolean': types.BooleanType,
#         'null': types.NullType,
#         'array': types.ArrayType,
#         'object': types.ObjectType,
#         'date': types.DateType,
#         'time': types.TimeType,
#         'datetime': types.DateTimeType,
#         'geopoint': types.GeoPointType,
#         'geojson': types.GeoJSONType,
#         'any': types.AnyType,
#     }
#
#     string_types = {
#         'string': types.StringType,
#     }
#
#     def setUp(self):
#         super(TestNullValues, self).setUp()
#         self.field = {
#             'name': 'Name',
#             'type': 'string',
#             'format': 'default',
#             'constraints': {
#                 'required': True,
#             }
#         }
#
#     def test_required_field_non_string_types(self):
#         error = exceptions.ConstraintError
#         for name, value in self.none_string_types.items():
#             self.field['type'] = name
#             _type = value(self.field)
#             self.assertRaises(error, _type.cast, 'null')
#             self.assertRaises(error, _type.cast, 'none')
#             self.assertRaises(error, _type.cast, 'nil')
#             self.assertRaises(error, _type.cast, 'nan')
#             self.assertRaises(error, _type.cast, '-')
#             self.assertRaises(error, _type.cast, '')
#
#     def test_required_field_string_types(self):
#         error = exceptions.ConstraintError
#         for name, value in self.string_types.items():
#             self.field['type'] = name
#             _type = value(self.field)
#             self.assertRaises(error, _type.cast, 'null')
#             self.assertRaises(error, _type.cast, 'none')
#             self.assertRaises(error, _type.cast, 'nil')
#             self.assertRaises(error, _type.cast, 'nan')
#             self.assertRaises(error, _type.cast, '-')
#             assert _type.cast('') == ''
#
#     def test_optional_field_non_string_types(self):
#         self.field['constraints']['required'] = False
#         for name, value in self.none_string_types.items():
#             self.field['type'] = name
#             _type = value(self.field)
#             assert _type.cast('null') == None
#             assert _type.cast('none') == None
#             assert _type.cast('nil') == None
#             assert _type.cast('nan') == None
#             assert _type.cast('-') == None
#             assert _type.cast('') == None
#
#     def test_optional_field_non_string_types(self):
#         self.field['constraints']['required'] = False
#         for name, value in self.string_types.items():
#             self.field['type'] = name
#             _type = value(self.field)
#             assert _type.cast('null') == None
#             assert _type.cast('none') == None
#             assert _type.cast('nil') == None
#             assert _type.cast('nan') == None
#             assert _type.cast('-') == None
#             assert _type.cast('') == ''
#
#
# class TestAny(base.BaseTestCase):
#     def setUp(self):
#         super(TestAny, self).setUp()
#         self.field = {
#             'name': 'Name',
#             'type': 'any',
#             'format': 'default',
#             'constraints': {
#                 'required': True
#             }
#         }
#
#     def test_any_type(self):
#         for value in ['1', 2, time(12, 0, 0)]:
#             _type = types.AnyType(self.field)
#             self.assertEquals(_type.cast(value), value)

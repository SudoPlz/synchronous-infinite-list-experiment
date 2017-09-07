import React, { Component } from 'react';
import { AppRegistry,
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  requireNativeComponent,
  findNodeHandle,
  TextInput,
  NativeModules,
} from 'react-native';

import SyncRegistry from './lib/SyncRegistry';
const RNInfiniteScrollViewChildren = requireNativeComponent('RNInfiniteScrollViewChildren', null);




class RNInfiniteScrollViewRowTemplate extends Component {
  render() {
    return (
      <View style={{padding: 10, width: 120, height: 80, backgroundColor: 'red'}}>
        <TextInput
          style={{ backgroundColor: 'blue', flexGrow: 1 }}
          editable={false}
          value={this.props.rowValue}
        />
      </View>
    );
  }
}

SyncRegistry.registerComponent('RNInfiniteScrollViewRowTemplate', () => RNInfiniteScrollViewRowTemplate, ['rowValue']);
var IScrollManager = NativeModules.RNInfiniteScrollViewChildrenManager;

class example extends Component {
  componentWillMount() {
    setTimeout(() => {
      IScrollManager.prepareRows();
    }, 1000)
  }
  render() {
    return (
      <View style={styles.container}>
        <RNInfiniteScrollViewChildren
          style={{flex: 1, backgroundColor: 'red' }}
          rowHeight={300}
          numRenderRows={5}
        />
      </View>
    );
  }
}


const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#D5D7FF',
  },
});

AppRegistry.registerComponent('example', () => example);

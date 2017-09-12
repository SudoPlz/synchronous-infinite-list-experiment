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
  Dimensions
} from 'react-native';

import SyncRegistry from './lib/SyncRegistry';
const RNInfiniteScrollViewChildren = requireNativeComponent('RNInfiniteScrollViewChildren', null);




class RNInfiniteScrollViewRowTemplate extends Component {
  render() {
    return (
      <View style={{padding: 10, width: 120, height: 80, backgroundColor: 'red'}}>
        <TextInput
          style={{ backgroundColor: 'yellow', flexGrow: 1 }}
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
    }, 500);

    // setTimeout(() => {
    //   IScrollManager.appendDataToDataSource(['Row 16', 'Row 17', 'Row 18']);
    // }, 1000);
  }
  render() {
    /**
     * 3 loopModes supported:
     * 
     * no-loop,
     * repeat-empty,
     * repeat-edge,
     */
    return (
      <View style={styles.container}>
        <RNInfiniteScrollViewChildren
          style={{ top: 0, width: Dimensions.get('window').width, height: Dimensions.get('window').height, backgroundColor: 'pink' }}
          rowHeight={130}
          numRenderRows={8}
          data={["Row 1", "Row 2", "Row 3", "Row 4", "Row 5", "Row 6", "Row 7", "Row 8", "Row 9", "Row 10", "Row 11", "Row 12", "Row 13", "Row 14", "Row 15"]}
          loopMode="repeat-empty"
          initialPosition={4}
        />
      </View>
    );
  }
}


const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#D5D7FF',
  },
});

AppRegistry.registerComponent('example', () => example);
